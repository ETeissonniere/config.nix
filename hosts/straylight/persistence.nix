{
  fileSystems."/nix" = {
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/home";
      inInitrd = true;
    }
    {
      directory = "/etc/ssh";
      inInitrd = true;
    }
    "/var/lib/sbctl"
    "/var/lib/docker"
  ];
}
