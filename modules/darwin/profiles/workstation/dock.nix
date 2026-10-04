{
  config,
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
      "/Applications/Nix Apps/Google Chrome.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Messages.app"
      "/System/Applications/Notes.app"
      "/System/Applications/Calendar.app"
      "/Applications/Nix Apps/Ghostty.app"
      "/Applications/ChatGPT.app"
      "${config.users.users.${config.me.username}.home}/Applications/Home Manager Apps/Zed.app"
      "/Applications/BambuStudio.app"
    ];

    persistent-others = [
      { folder = "${config.users.users.${config.me.username}.home}/Downloads"; }
    ];
  };
}
