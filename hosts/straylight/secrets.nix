{
  config,
  lib,
  ...
}:
{
  age.secrets = {
    # Straylight's Cloudflare token, decrypted again so slopcannon gets none of slopkiddy's secrets.
    slopcannon-caddy-environment = {
      rekeyFile = ../../secrets/straylight/slopkiddy-caddy-environment.age;
      path = "${config.age.secretsMountPoint}/services/slopcannon/slopcannon-caddy-environment";
      symlink = false;
    };
  }
  //
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
