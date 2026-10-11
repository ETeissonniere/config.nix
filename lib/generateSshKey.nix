{ lib, pkgs }:
{
  path,
  owner ? "root",
}:
let
  key = lib.escapeShellArg path;
  directory = lib.escapeShellArg (builtins.dirOf path);
  user = lib.escapeShellArg owner;
in
''
  ${pkgs.coreutils}/bin/install -d -m 700 -o ${user} ${directory} || exit 1
  if [ ! -e ${key} ]; then
    (umask 077; ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -f ${key}) || exit 1
  fi
  ${pkgs.coreutils}/bin/chown ${user} ${key} || exit 1
  ${pkgs.coreutils}/bin/chmod 600 ${key} || exit 1
  ssh_public_key=$(${pkgs.openssh}/bin/ssh-keygen -y -P "" -f ${key}) || exit 1
  printf '%s\n' "$ssh_public_key" > ${key}.pub || exit 1
  ${pkgs.coreutils}/bin/chown ${user} ${key}.pub || exit 1
''
