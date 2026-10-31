host := lowercase(if os() == 'macos' { `scutil --get LocalHostName` } else { `hostname` })
flake := 'path:' + justfile_directory()
nix := "nix --extra-experimental-features 'nix-command flakes'"

default:
    @just --list

# Evaluate the configuration
check target=host:
    {{ nix }} eval "{{ flake }}#configurationPaths.{{ target }}"

# Evaluate all Darwin and NixOS configurations
check-all:
    # Evaluate first so agenix-rekey can register its ciphertext paths in the store.
    {{ nix }} eval --json "{{ flake }}#configurationPaths"
    {{ nix }} flake check --no-build --all-systems "{{ flake }}"

# Run discovered VM tests on this platform
test:
    {{ nix }} build "{{ flake }}#tests" --no-link -L

# Build the deployment closure without activating (NixOS), or the Darwin system
build target=host:
    if [ -f "{{ justfile_directory() }}/hosts/{{ target }}/configuration.nix" ]; then \
        {{ nix }} build "{{ flake }}#deploy.nodes.{{ target }}.profiles.system.path" --no-link; \
    else \
        nh darwin build "{{ flake }}" --hostname "{{ target }}"; \
    fi

# Build and activate with nh
switch:
    nh darwin switch "{{ flake }}" --hostname "{{ host }}"

# Update pinned dependencies without applying
update:
    {{ nix }} flake update --flake "{{ flake }}"

# Format Nix files and recipes
format:
    just --fmt
    {{ nix }} fmt -- --tree-root "{{ justfile_directory() }}"

# Install on an empty machine; this ERASES the disks configured for the host
[confirm('This erases the target disks. Have you checked the address and host disk configuration?')]
install target address *args:
    {{ nix }} run "{{ flake }}#nixos-anywhere" -- --build-on local --flake "{{ flake }}#{{ target }}" --target-host "{{ address }}" {{ args }}

# Check only the selected host; CI runs the full flake checks and VM tests.
# Build on the target and deploy with automatic rollback
deploy target *args: (check target)
    {{ nix }} run "{{ flake }}#deploy-rs" -- "{{ flake }}#{{ target }}" --remote-build --skip-checks {{ args }}

# Build using the local Nix builders and deploy with automatic rollback
deploy-local target *args: (check target)
    {{ nix }} run "{{ flake }}#deploy-rs" -- "{{ flake }}#{{ target }}" --skip-checks {{ args }}

# Edit a secret with $EDITOR (defaults to nvim)
secret name:
    EDITOR="${EDITOR:-nvim}" {{ nix }} run "{{ flake }}#agenix-edit-view" -- edit "secrets/{{ name }}.age"

# Refresh host ciphertext after editing secrets or changing host recipients
secrets-rekey identity="$HOME/.config/age/identity.key":
    AGENIX_IDENTITY="{{ identity }}" {{ nix }} run "{{ flake }}#agenix-rekey"
