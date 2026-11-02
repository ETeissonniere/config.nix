{ inputs, ... }:
{
  imports = [ inputs.self.homeModules.profiles.workstation ];

  # Compatibility baseline for this installation; do not bump during updates.
  home.stateVersion = "26.05";
}
