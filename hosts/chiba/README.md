# Chiba

Chiba is a small network auxiliary host. It runs CoreDNS, Tailscale, Pocket ID, and a shared reverse proxy in separate containers.

It uses a static IP (handy for DNS) unlike our other hosts. Additionally, it runs on a relatively RAM limited
Raspberry Pi 5 (2Gb RAM only). As a result, we had to tune our configuration to keep usage low.

Following our `straylight` config, every service like CoreDNS or Tailscale are running within their own containers
with limited persistence. Additionally, this host does follow our immutable configuration, with a `tmpfs` for the
root partition, which has the nice benefit of helping preserve the SD Card.
