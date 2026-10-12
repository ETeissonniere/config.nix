# Sourced by the pinned image before systemd starts. Its custom system files
# ship writable by all users, including the directories containing them.
find /usr/local /usr/lib/systemd /etc/systemd /etc/xdg -xdev \
  -user root \( -type f -o -type d \) -perm /0022 -exec chmod go-w {} +
