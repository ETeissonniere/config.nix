{
  config,
  inputs,
  hostName,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.darwinModules.profiles.workstation
    inputs.self.lib.commonModules.nix-builders
    inputs.self.darwinModules.nas
    inputs.self.darwinModules.time-machine
    ./secrets.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.settings.trusted-users = lib.mkForce [ "root" ];
  system.activationScripts.preActivation.text = ''
    if [ ! -e /etc/nix/straylight_builder_ed25519 ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" \
        -C wintermute-builder -f /etc/nix/straylight_builder_ed25519
    fi
    chown root:wheel /etc/nix/straylight_builder_ed25519
    chmod 600 /etc/nix/straylight_builder_ed25519
  '';
  nix.linux-builder.enable = true; # For Raspberry Pi hosts.
  nix.linux-builder.config.virtualisation = {
    darwin-builder.diskSize = 64 * 1024;
    fileSystems."/".autoResize = true;
  };
  launchd.daemons.linux-builder.serviceConfig = {
    RunAtLoad = lib.mkForce false;
    KeepAlive = lib.mkForce false;
  };
  networking = {
    inherit hostName;
    computerName = lib.strings.toSentenceCase hostName;
    localHostName = hostName;
  };

  users.users.${config.me.username}.uid = 501;

  services.nas = {
    enable = true;
    server = "nas.teiss.org";
    account = "Eliott";
    shares = [ "personal_folder" ];
    encryptedPasswordFile = config.age.secrets.nas-password.rekeyFile;
  };
  services.time-machine = {
    enable = true;
    inherit (config.services.nas) server account passwordCommand;
    share = "Eliott's Time Machine";
    credentialRevision = builtins.hashFile "sha256" config.services.nas.encryptedPasswordFile;
    exclusions = map (path: "${config.users.users.${config.me.username}.home}/${path}") [
      "Developer"
      "Downloads"
    ];
  };

  # Compatibility baseline for this installation; do not bump during updates.
  system.stateVersion = 6;
}
