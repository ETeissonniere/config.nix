set -euo pipefail
# Connections cover transfers and builds; build users also cover
# work that continues after the client disconnects.
connections=$(ss -Htn state established '( sport = :22 )')
users=$(ps -eo user=)
read -r uptime _ < /proc/uptime
now=${uptime%%.*}
state=/run/builder-idle-since
if [ -n "$connections" ] || grep -q '^nixbld' <<< "$users"; then
  rm -f "$state"
elif [ ! -e "$state" ]; then
  echo "$now" > "$state"
elif [ "$((now - $(cat "$state")))" -ge "$IDLE_TIMEOUT" ]; then
  systemctl poweroff
fi
