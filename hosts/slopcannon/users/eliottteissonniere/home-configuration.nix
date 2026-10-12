{ inputs, ... }:
{
  imports = [ inputs.self.homeModules.profiles.coding ];

  services.codex-remote-control.enable = true;

  home.stateVersion = "26.05";
}
