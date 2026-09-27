{ inputs, ... }:
{
  imports = [ inputs.self.homeModules.default ];

  # Compatibility baseline for this installation; do not bump during updates.
  home.stateVersion = "26.05";
}
