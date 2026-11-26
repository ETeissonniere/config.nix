{ inputs, ... }:
{
  imports = [ inputs.rex.homeManagerModules.default ];

  # On a Mac, the Rex app runs the server; this adds the rex command and its terminfo.
  programs.rex.enable = true;
}
