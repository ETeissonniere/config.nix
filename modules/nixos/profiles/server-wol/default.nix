{
  systemd.network.links."10-wake-on-lan" = {
    matchConfig = {
      Type = "ether";
      Path = "pci-*";
    };
    linkConfig = {
      NamePolicy = "keep kernel database onboard slot path";
      WakeOnLan = "magic";
    };
  };
}
