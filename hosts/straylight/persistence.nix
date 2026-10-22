{
  fileSystems."/nix" = {
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  preservation.preserveAt."/persist".directories = [
    "/var/lib/sbctl"
    "/var/lib/docker"
  ];
}
