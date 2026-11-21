# Temporary directories kept on disk and emptied at boot. systemd's tmp.conf still
# removes files older than 10 days (/tmp) and 30 days (/var/tmp).
rec {
  directories = [
    "/tmp"
    "/var/tmp"
  ];
  # '!' applies at boot only, so rebuilds do not delete files in use.
  wipeRules = map (directory: "D! ${directory} 1777 root root") directories;
}
