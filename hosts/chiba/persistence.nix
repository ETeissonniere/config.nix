{
  fileSystems."/nix" = {
    neededForBoot = true;
    depends = [ "/persist" ];
  };
}
