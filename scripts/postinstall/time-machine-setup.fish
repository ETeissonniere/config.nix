#!/usr/bin/env fish

set server nas.teiss.org
set account Eliott
set share "Eliott's Time Machine"
set exclusions "$HOME/Developer" "$HOME/Downloads"

if test (id -u) -eq 0
    echo "Run time-machine-setup as your normal user, without sudo." >&2
    exit 1
end
if not isatty stdin
    echo "Run time-machine-setup in a terminal for the NAS password prompt." >&2
    exit 1
end

set username (jq -rn --arg value "$account" '$value | @uri')
or exit 1
set encoded_share (jq -rn --arg value "$share" '$value | @uri')
or exit 1
set url "smb://$username@$server/$encoded_share"
set raw_url "smb://$account@$server/$share"

# macOS versions can report URLs with either escaped or literal share names.
set destinations (/usr/bin/sudo /usr/bin/tmutil destinationinfo -X)
or set destinations
if printf '%s\n' $destinations | /usr/bin/plutil -convert json -o - -- - 2>/dev/null |
        jq -e --arg url "$url" --arg raw_url "$raw_url" \
            'any(.. | objects; .URL? == $url or .URL? == $raw_url)' >/dev/null
    echo "The configured Time Machine destination is already registered."
else
    echo "Registering $url. Enter the NAS password when prompted."
    echo "The terminal needs Full Disk Access in System Settings > Privacy & Security."
    # -a preserves other destinations; -p keeps the password out of process arguments.
    /usr/bin/sudo /usr/bin/tmutil setdestination -a -p "$url"
    or exit 1
end
# Path exclusions also cover directories that do not exist yet. Removing an entry
# here does not undo it; use tmutil removeexclusion -p for that.
/usr/bin/sudo /usr/bin/tmutil addexclusion -p $exclusions
or exit 1
/usr/bin/sudo /usr/bin/tmutil enable
or exit 1
echo "Automatic Time Machine backups are enabled."
