{ pkgs }:
pkgs.runCommand "time-machine-password-tests"
  {
    nativeBuildInputs = with pkgs; [
      bash
      age
    ];
  }
  ''
    mkdir -p repo/scripts/provision repo/hosts/wintermute repo/secrets/recipients
    touch repo/hosts/wintermute/darwin-configuration.nix
    # Import preserves an existing password exactly and refuses to replace it.
    cp ${../scripts/provision/import-time-machine-password.sh} repo/scripts/provision/import-time-machine-password.sh
    cp ${../secrets/recipients/wintermute.pub} repo/secrets/recipients/wintermute.pub
    age-keygen -pq -o recovery.key 2>/dev/null
    age-keygen -y recovery.key > repo/secrets/recipients/recovery.pub
    if bash repo/scripts/provision/import-time-machine-password.sh ../wintermute; then exit 1; fi
    if bash repo/scripts/provision/import-time-machine-password.sh wintermute </dev/null; then exit 1; fi
    test ! -e repo/secrets/wintermute/time-machine-password.age
    if printf '\n' | bash repo/scripts/provision/import-time-machine-password.sh wintermute; then exit 1; fi
    test ! -e repo/secrets/wintermute/time-machine-password.age
    # Failed encryption must leave the import retryable and remove temporary files.
    mv repo/secrets/recipients/recovery.pub recovery.pub
    if printf '%s\n' 'synthetic password' | bash repo/scripts/provision/import-time-machine-password.sh wintermute; then exit 1; fi
    test -z "$(ls -A repo/secrets/wintermute)"
    mv recovery.pub repo/secrets/recipients/recovery.pub
    printf '%s' '  synthetic \\ backup password  ' > expected-password
    printf '%s\n' '  synthetic \\ backup password  ' |
      bash repo/scripts/provision/import-time-machine-password.sh wintermute
    age -d -i recovery.key repo/secrets/wintermute/time-machine-password.age > actual-password
    cmp expected-password actual-password
    cp repo/secrets/wintermute/time-machine-password.age imported.age
    if bash repo/scripts/provision/import-time-machine-password.sh wintermute; then exit 1; fi
    cmp imported.age repo/secrets/wintermute/time-machine-password.age

    touch "$out"
  ''
