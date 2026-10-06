{ inputs, ... }:
{
  imports = [
    inputs.self.homeModules.profiles.workstation
    ./vscode.nix
  ];

  programs.scauth.identities.default.touchId = false;

  # Nix owns Linear updates; its built-in updater cannot modify the store.
  targets.darwin.defaults."com.linear".AutoUpdateDisabled = true;

  # Compatibility baseline for this installation; do not bump during updates.
  home.stateVersion = "26.05";
}
