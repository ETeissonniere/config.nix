{
  fileSystems."/nix" = {
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  # Builds and agents need more scratch space than RAM should hold.
  ephemeralRoot.scratchOnDisk = true;

  preservation.preserveAt."/persist".directories = [
    "/var/lib/sbctl"
  ];
}
