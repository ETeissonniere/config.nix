# Distributed builds connect as root through the Nix daemon.
while [ "$SECONDS" -lt "$STARTUP_TIMEOUT" ]; do
  /bin/launchctl kickstart system/org.nixos.linux-builder
  if ssh -o ProxyCommand=none -o BatchMode=yes -o ConnectTimeout=2 builder@linux-builder true </dev/null 2>/dev/null; then
    exec /usr/bin/nc 127.0.0.1 31022
  fi
  sleep 1
done
echo "Linux builder did not become reachable within $STARTUP_TIMEOUT seconds" >&2
exit 1
