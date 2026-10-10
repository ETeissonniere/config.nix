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
build:
    nh darwin build "{{ flake }}" --hostname "{{ host }}"

# Build and activate with nh
switch:
    nh darwin switch "{{ flake }}" --hostname "{{ host }}"

# Set up Time Machine interactively
postinstall:
    fish scripts/postinstall/time-machine-setup.fish

# Update pinned dependencies without applying
update:
    {{ nix }} flake update --flake "{{ flake }}"

# Encrypt or edit a secret with the operator's external master identity
secret-edit file:
    {{ nix }} run "{{ flake }}#agenix-rekey.$({{ nix }} eval --impure --raw --expr builtins.currentSystem).edit-view" -- edit "{{ file }}"

# Encrypt configured secrets for each host's public identity
rekey:
    {{ nix }} run "{{ flake }}#agenix-rekey.$({{ nix }} eval --impure --raw --expr builtins.currentSystem).rekey"

# Re-encrypt existing master secrets after changing operator/recovery recipients
update-masterkeys:
    {{ nix }} run "{{ flake }}#agenix-rekey.$({{ nix }} eval --impure --raw --expr builtins.currentSystem).update-masterkeys"

# Format Nix files and recipes
format:
    just --fmt
    {{ nix }} run "{{ flake }}#formatter.$({{ nix }} eval --impure --raw --expr builtins.currentSystem)" -- --tree-root "{{ justfile_directory() }}"
