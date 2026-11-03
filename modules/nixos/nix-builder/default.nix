{ lib, ... }:
let
  keys = import ../../common/keys.nix;
in
{
  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    trusted = true;
    keys = [
      keys.wintermute-builder
    ]
    ++ lib.optional (keys ? armitage-builder) keys.armitage-builder;
  };
}
