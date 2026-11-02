{
  pkgs,
  user,
  agePasswordFile,
  ageIdentityFile,
}:
let
  lib = pkgs.lib;
in
# Return a runtime script whose stdout is piped directly to a password consumer.
pkgs.writeShellScript "decrypt-age-se-password" ''
  set -euo pipefail
  # launchctl selects the login session; sudo changes the process credentials.
  if [ "$(/usr/bin/id -u)" != "${toString user.uid}" ]; then
    exec /bin/launchctl asuser ${toString user.uid} \
      /usr/bin/sudo -H -u ${lib.escapeShellArg user.name} "$0"
  fi
  export PATH=${
    lib.makeBinPath [
      pkgs.age
      pkgs.age-plugin-se
    ]
  }:/usr/bin:/bin
  exec age --decrypt -i ${lib.escapeShellArg ageIdentityFile} ${lib.escapeShellArg agePasswordFile}
''
