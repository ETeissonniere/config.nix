{
  # Load a project's Nix dev shell on cd, and cache it between visits.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
