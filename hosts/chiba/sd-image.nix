{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];
  # Keep the image boot support without the installer's repair tools and filesystems.
  disabledModules = [ "profiles/base.nix" ];

  # The SD image's ext4 partition holds the store, boot files and preserved state.
  fileSystems = {
    "/" = {
      device = lib.mkForce "none";
      fsType = lib.mkForce "tmpfs";
    };
    "/persist" = {
      device = "/dev/disk/by-label/${config.sdImage.rootVolumeLabel}";
      fsType = "ext4";
    };
    "/nix" = {
      device = "/persist/nix";
      fsType = "none";
      options = [ "bind" ];
    };
    "/boot" = {
      device = "/persist/boot";
      fsType = "none";
      options = [ "bind" ];
      depends = [ "/persist" ];
    };
  };
  sdImage.nixPathRegistrationFile = "/persist/nix-path-registration";

  # Expand the SD card's ext4 partition on first boot.
  # Locate it through /persist because / is a RAM-backed tmpfs.
  systemd.services.expand-root-partition = {
    path = [
      pkgs.util-linux
      pkgs.parted
      pkgs.e2fsprogs
    ];
    script = lib.mkForce ''
      rootPart=$(findmnt -n -o SOURCE /persist)
      bootDevice=$(lsblk -npo PKNAME "$rootPart")
      partNum=$(cat "/sys/class/block/$(basename "$rootPart")/partition")
      echo ",+," | sfdisk -N"$partNum" --no-reread "$bootDevice"
      partprobe
      resize2fs "$rootPart"
    '';
  };
}
