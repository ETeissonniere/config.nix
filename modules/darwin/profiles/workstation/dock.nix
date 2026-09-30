{
  config,
  pkgs,
  ...
}:
{
  system.defaults.dock = {
    autohide = true;
    tilesize = 64;

    # No hot corners.
    wvous-tl-corner = 1;
    wvous-tr-corner = 1;
    wvous-bl-corner = 1;
    wvous-br-corner = 1;

    persistent-apps = [
      "/Applications/Google Chrome.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Messages.app"
      "/System/Applications/Notes.app"
      "/System/Applications/Calendar.app"
      "/Applications/Ghostty.app"
      "/Applications/ChatGPT.app"
      "${pkgs.zed-editor}/Applications/Zed.app"
      "/Applications/BambuStudio.app"
      "/System/Applications/Siri.app"
    ];

    persistent-others = [
      { folder = "${config.users.users.${config.me.username}.home}/Downloads"; }
    ];
  };
}
