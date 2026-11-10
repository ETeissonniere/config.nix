# Distributed builds connect as root through the Nix daemon.
/bin/launchctl kickstart system/org.nixos.linux-builder

# QEMU accepts TCP before sshd is ready. Wait for its banner on the connection
# Nix will use, so parallel builds don't open extra unauthenticated SSH sessions.
while (( SECONDS < STARTUP_TIMEOUT )); do
  if { exec 3<>/dev/tcp/127.0.0.1/31022; } 2>/dev/null; then
    if IFS= read -r -u 3 -t 2 -n 4 prefix && [[ "$prefix" == SSH- ]]; then
      printf '%s' "$prefix"
      exec socat STDIO FD:3
    fi
    exec 3>&-
  fi
  sleep 1
done
echo "Linux builder did not become reachable within $STARTUP_TIMEOUT seconds" >&2
exit 1
