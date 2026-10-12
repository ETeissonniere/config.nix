let
  encryptedFilesystem = name: mountpoint: {
    type = "luks";
    inherit name;
    # Supplied to the installer out of band, never placed in the Nix store.
    passwordFile = "/tmp/straylight-disk-password";
    settings.crypttabExtraOpts = [ "tpm2-device=auto" ];
    content = {
      type = "filesystem";
      format = "ext4";
      inherit mountpoint;
    };
  };
in
{
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/disk/by-path/pci-0000:10:00.0-nvme-1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = encryptedFilesystem "cryptroot" "/";
        };
      };
    };
  };
  disko.devices.disk.data = {
    type = "disk";
    device = "/dev/disk/by-path/pci-0000:02:00.0-nvme-1";
    content = {
      type = "gpt";
      partitions.data = {
        size = "100%";
        content = encryptedFilesystem "cryptdata" "/data";
      };
    };
  };
}
