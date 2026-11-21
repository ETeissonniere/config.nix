{
  fileSystems."/nix" = {
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  # Builds and agents need more /tmp space than RAM should hold. Containers follow.
  ephemeralRoot.tmpOnDisk = true;

  preservation.preserveAt."/persist".directories = [
    "/var/lib/sbctl"
  ];
}
