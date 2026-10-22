{ config, lib, ... }:
{
  options.nixBuilder.emulation.enable = lib.mkEnableOption "ARM Linux build emulation";

  config = {
    boot.binfmt.emulatedSystems = lib.mkIf config.nixBuilder.emulation.enable [ "aarch64-linux" ];

    nix.sshServe = {
      enable = true;
      protocol = "ssh-ng";
      write = true;
      trusted = true;
      keys = [ (lib.trim (builtins.readFile ../../common/keys/wintermute-builder.pub)) ];
    };
  };
}
