{ lib, ... }:
{
  options.me.username = lib.mkOption {
    type = lib.types.str;
    default = "eliottteissonniere";
    description = "Primary user shared by all hosts.";
  };
}
