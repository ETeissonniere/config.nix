host := lowercase(if os() == 'macos' { `scutil --get LocalHostName` } else { `hostname` })
flake := 'path:' + justfile_directory()
nix := "nix --extra-experimental-features 'nix-command flakes'"

default:
    @just --list

# Evaluate the configuration
check:
    {{ nix }} flake check --no-build "{{ flake }}"
    {{ nix }} eval "{{ flake }}#darwinConfigurations.{{ host }}.system.drvPath"

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
    #!/usr/bin/env fish
    if test -f "{{ justfile_directory() }}/hosts/{{ target }}/darwin-configuration.nix"
        nh darwin build "{{ flake }}" --hostname "{{ target }}"
    else
        nh os build "{{ flake }}" --hostname "{{ target }}"
    end

# Build and activate with nh
switch:
    nh darwin switch "{{ flake }}" --hostname "{{ host }}"

# Set up Time Machine interactively
postinstall:
    fish scripts/postinstall/time-machine-setup.fish

# Export SSH public keys configured on the current host for provisioning on our servers
# Currently macOS-only because this assumes scauth is available
export-ssh-keys:
    #!/usr/bin/env fish
    set admin_key (scauth pubkey default); or exit 1
    set builder_key (sudo cat /var/root/.ssh/nix-builder.pub); or exit 1
    mkdir -p secrets/public-keys/ssh/admin secrets/public-keys/ssh/builders; or exit 1
    printf '%s\n' "$admin_key" > secrets/public-keys/ssh/admin/{{ host }}.pub; or exit 1
    printf '%s\n' "$builder_key" > secrets/public-keys/ssh/builders/{{ host }}.pub; or exit 1

# Update pinned dependencies without applying
update:
    {{ nix }} flake update --flake "{{ flake }}"

# Deploy a NixOS host with deploy-rs rollback protections
deploy target='lxc-builder':
    {{ nix }} run --inputs-from "{{ flake }}" deploy-rs -- "{{ flake }}#{{ target }}"

# Format Nix files and recipes
format:
    just --fmt
    {{ nix }} run "{{ flake }}#formatter.$({{ nix }} eval --impure --raw --expr builtins.currentSystem)" -- --tree-root "{{ justfile_directory() }}"
