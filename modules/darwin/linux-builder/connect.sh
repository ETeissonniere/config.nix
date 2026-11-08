# Distributed builds connect as root through the Nix daemon.
while [ "$SECONDS" -lt "$STARTUP_TIMEOUT" ]; do
  /bin/launchctl kickstart system/org.nixos.linux-builder
  # Nix supplies host-key verification to the outer SSH connection, not this probe.
  if ssh-keyscan -T 2 -t ed25519 -p 31022 127.0.0.1 >/dev/null 2>&1; then
    exec /usr/bin/nc 127.0.0.1 31022
  fi
  sleep 1
done
echo "Linux builder did not become reachable within $STARTUP_TIMEOUT seconds" >&2
exit 1
