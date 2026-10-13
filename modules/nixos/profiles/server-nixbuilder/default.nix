{ inputs, lib, ... }:
{
  imports = [ inputs.self.nixosModules.profiles.server ];

  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    trusted = true;
    keys = [ (lib.trim (builtins.readFile ../../../common/keys/wintermute-builder.pub)) ];
  };
}
