host := lowercase(if os() == 'macos' { `scutil --get LocalHostName` } else { `hostname` })
flake := 'path:' + justfile_directory()
nix := "nix --extra-experimental-features 'nix-command flakes'"

default:
    @just --list

# Evaluate the configuration
check target=host:
    {{ nix }} flake check --no-build "{{ flake }}"
    if [ -f "{{ justfile_directory() }}/hosts/{{ target }}/configuration.nix" ]; then \
        {{ nix }} eval "{{ flake }}#nixosConfigurations.{{ target }}.config.system.build.toplevel.drvPath"; \
    else \
        {{ nix }} eval "{{ flake }}#darwinConfigurations.{{ target }}.system.drvPath"; \
    fi

# Evaluate all Darwin and NixOS configurations
check-all:
    {{ nix }} flake check --no-build --all-systems "{{ flake }}"
    {{ nix }} eval --impure --json \
        --expr 'builtins.getFlake "{{ flake }}"' \
        --apply 'flake: { \
            darwinConfigurations = builtins.mapAttrs \
                (_: host: host.system.drvPath) \
                (flake.darwinConfigurations or {}); \
            nixosConfigurations = builtins.mapAttrs \
                (_: host: host.config.system.build.toplevel.drvPath) \
                (flake.nixosConfigurations or {}); \
        }'

# Build without activating
build target=host:
    if [ -f "{{ justfile_directory() }}/hosts/{{ target }}/configuration.nix" ]; then \
        {{ nix }} build "{{ flake }}#nixosConfigurations.{{ target }}.config.system.build.toplevel" --no-link; \
    else \
        nh darwin build "{{ flake }}" --hostname "{{ target }}"; \
    fi

# Build and activate with nh
switch:
    nh darwin switch "{{ flake }}" --hostname "{{ host }}"

# Set up Time Machine interactively
postinstall:
    fish scripts/postinstall/time-machine-setup.fish

# Update pinned dependencies without applying
update:
    {{ nix }} flake update --flake "{{ flake }}"

# Format Nix files and recipes
format:
    just --fmt
    {{ nix }} run "{{ flake }}#formatter.$({{ nix }} eval --impure --raw --expr builtins.currentSystem)" -- --tree-root "{{ justfile_directory() }}"

# Install on an empty machine; this ERASES the disks configured for the host
[confirm('This erases the target disks. Have you checked the address and host disk configuration?')]
install target address *args:
    {{ nix }} run "{{ flake }}#nixos-anywhere" -- --build-on local --flake "{{ flake }}#{{ target }}" --target-host "{{ address }}" {{ args }}

# Deploy updates with automatic rollback if activation/connectivity fails
deploy target *args:
    {{ nix }} run "{{ flake }}#deploy" -- "{{ flake }}#{{ target }}" {{ args }}
