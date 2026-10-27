#!/bin/sh
set -e
for i in $(ls /sys/class/net | grep -v '^lo$'); do
  ethtool -K "$i" tso off gso off gro off 2>/dev/null \
    || echo "warn: could not disable offloads on $i" >&2
done
ip route replace 10.10.1.0/24 via 10.10.2.254
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
