{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    package = null;
    userSettings.telemetry = {
      diagnostics = false;
      metrics = false;
    };
    extensions = [
      "git-firefly"
      "nix"
      "toml"
    ];
  };

  home.sessionVariables = {
    EDITOR = "${pkgs.zed-editor.meta.mainProgram} --wait";
    VISUAL = "${pkgs.zed-editor.meta.mainProgram} --wait";
  };
}
