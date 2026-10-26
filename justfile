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

# Start the local ARM Linux builder (off by default)
builder-start:
    sudo launchctl kickstart system/org.nixos.linux-builder

# Shut down the builder gracefully; finish any builds first
builder-stop:
    sudo ssh -o ConnectTimeout=5 builder@linux-builder shutdown -h now

# Connect Wintermute's NAS share and set up Time Machine interactively
postinstall:
    if [ "{{ host }}" = wintermute ]; then \
        /usr/bin/open -a Finder 'smb://Eliott@nas.teiss.org/personal_folder'; \
    fi
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

# Build on the target and deploy with automatic rollback
deploy target *args:
    {{ nix }} run "{{ flake }}#deploy" -- "{{ flake }}#{{ target }}" --remote-build {{ args }}

# Build using the local Nix builders and deploy with automatic rollback
deploy-local target *args:
    {{ nix }} run "{{ flake }}#deploy" -- "{{ flake }}#{{ target }}" {{ args }}
