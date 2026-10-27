#!/bin/sh
# Disable segmentation/receive offloads on every non-loopback interface so
# netem sees (and drops) individual MTU-sized packets, not GSO super-packets.
for i in $(ls /sys/class/net | grep -v '^lo$'); do
  ethtool -K "$i" tso off gso off gro off 2>/dev/null \
    || echo "warn: could not disable offloads on $i" >&2
done
