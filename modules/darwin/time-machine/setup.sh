destinations=$(tmutil destinationinfo -X 2>&1) || {
    if [ "$destinations" != "No destinations configured." ]; then
        echo >&2 "Cannot inspect Time Machine destinations; check Full Disk Access."
        exit 1
    fi
    destinations='<?xml version="1.0"?><plist version="1.0"><dict/></plist>'
}
destinations=$(printf '%s' "$destinations" | plutil -convert json -o - -- -)

# tmutil cannot configure backup encryption. Never start a new, potentially
# unencrypted backup automatically; adopt a destination configured in macOS.
if ! printf '%s' "$destinations" | jq -e --arg url "$destination" --arg raw "$rawDestination" \
        'any(.Destinations[]?; .URL == $url or .URL == $raw)' >/dev/null; then
    echo >&2 "Configure this Time Machine destination and backup encryption in System Settings before switching."
    exit 1
fi
if [ -f "$state/credential-revision" ] && [ "$(cat "$state/credential-revision")" != "$revision" ]; then
    registerDestination
fi
if [ "${#exclusions[@]}" -gt 0 ]; then
    tmutil addexclusion -p "${exclusions[@]}"
fi
tmutil enable
mkdir -p "$state"
printf '%s\n' "$revision" > "$state/credential-revision"
