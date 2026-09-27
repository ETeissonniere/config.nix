{ config, lib, ... }:
{
  config = lib.mkIf config.profiles.workstation.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = "Eliott Teissonniere";
          email = "git@eteiss.org";
        };
        core.autocrlf = "input";
        pull.rebase = true;
        submodule.recurse = true;
        push.autoSetupRemote = true;
        commit.gpgSign = true;
        init.defaultBranch = "master";
      };
      signing = {
        key = "~/.ssh/id_ed25519.pub";
        format = "ssh";
      };
      ignores = [
        ".DS_Store"
        ".AppleDouble"
        ".LSOverride"
        "Icon"
        "._*"
        ".DocumentRevisions-V100"
        ".fseventsd"
        ".Spotlight-V100"
        ".TemporaryItems"
        ".Trashes"
        ".VolumeIcon.icns"
        ".com.apple.timemachine.donotpresent"
        ".AppleDB"
        ".AppleDesktop"
        "Network Trash Folder"
        "Temporary Items"
        ".apdisk"
        "logs"
        "*.log"
        "npm-debug.log*"
        "yarn-debug.log*"
        "yarn-error.log*"
        ".vscode"
        ".zed"
      ];
    };
  };
}
