{
  pkgs,
  user,
  agePasswordFile,
  ageIdentityFile,
}:
let
  lib = pkgs.lib;
in
# Decrypt the password when this script runs and send it straight to the command
# that needs it, without saving a plaintext file.
pkgs.writeShellScript "decrypt-age-se-password" ''
  set -euo pipefail
  # If we're not already running as this user, restart in their login session
  # so they can approve access to their Secure Enclave key.
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
