{ config, inputs, ... }:
{
  imports = [ inputs.self.nixosModules.profiles.server ];

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  users.users.${config.me.username}.extraGroups = [ "docker" ];
}
