{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.self.nixosModules.secrets ];
  age.secrets =
    lib.genAttrs
      [
        "webui-environment"
        "searx-environment"
        "comfyui-oauth-environment"
        "slopkiddy-caddy-environment"
      ]
      (name: {
        rekeyFile = ../../secrets + "/straylight/${name}.age";
        path = "${config.age.secretsMountPoint}/services/slopkiddy/${name}";
        symlink = false;
      });
}
