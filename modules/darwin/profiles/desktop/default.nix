{ inputs, ... }:
{
  imports = [ inputs.self.darwinModules.linearmouse ];

  services.linearmouse.enable = true;
  homebrew.casks = [ "monitorcontrol" ];
}
