#!/bin/sh
set -e
for i in $(ls /sys/class/net | grep -v '^lo$'); do
  ethtool -K "$i" tso off gso off gro off 2>/dev/null \
    || echo "warn: could not disable offloads on $i" >&2
done
exec sleep infinity
