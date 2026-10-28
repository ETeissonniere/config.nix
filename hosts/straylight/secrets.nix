{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];
  age = {
    ageBin = "${pkgs.age}/bin/age";
    identityPaths = [ "/persist/agenix/straylight.key" ];
    secrets = builtins.listToAttrs (
      map
        (name: {
          inherit name;
          value = {
            file = ../../secrets + "/straylight/${name}.age";
            path = "${config.age.secretsMountPoint}/services/slopkiddy/${name}";
            symlink = false;
          };
        })
        [
          "webui-environment"
          "searx-environment"
          "comfyui-oauth-environment"
          "slopkiddy-caddy-environment"
        ]
    );
  };
  environment.systemPackages = [ pkgs.age ];
  assertions = map (secret: {
    assertion = builtins.pathExists secret.file;
    message = "Provision ${secret.name}.age under secrets/straylight before building or deploying Straylight.";
  }) (builtins.attrValues config.age.secrets);
  systemd.tmpfiles.rules = [ "d /persist/agenix 0700 root root -" ];
}
