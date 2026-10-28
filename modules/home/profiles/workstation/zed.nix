{ ... }:
{
  programs.zed-editor = {
    enable = true;
    userSettings.telemetry = {
      diagnostics = false;
      metrics = false;
    };
    extensions = [
      "git-firefly"
      "just"
      "nix"
      "toml"
    ];
  };
}
