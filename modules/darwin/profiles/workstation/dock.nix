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
      "/Applications/Google Chrome.app"
      "/System/Applications/Mail.app"
      "/System/Applications/Messages.app"
      "/System/Applications/Notes.app"
      "/System/Applications/Calendar.app"
      "/System/Applications/Reminders.app"
      "/Applications/Nix Apps/Ghostty.app"
      "/Applications/ChatGPT.app"
      "/Applications/Claude.app"
      "/Applications/Nix Apps/Zed.app"
      "/Applications/BambuStudio.app"
    ];

    persistent-others = [
      { folder = "${config.users.users.${config.me.username}.home}/Downloads"; }
    ];
  };
}
