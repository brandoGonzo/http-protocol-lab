#!/bin/sh
# usage: netem clean|rtt50|rtt150|loss1|loss2|loss5|custom|show
# custom: RTT_MS=<round trip ms> LOSS_PCT=<downlink loss %>
# Delay is split evenly across both directions; loss applies to the downlink (server -> client).
# Applying a profile deletes and re-adds the qdisc so counters start at zero.
set -e
UP=$(ip -o -4 addr show | awk '/10\.10\.2\.254/{print $2}')
DOWN=$(ip -o -4 addr show | awk '/10\.10\.1\.254/{print $2}')
LIMIT=10000
d=""
l=0

reset() {
  tc qdisc del dev "$UP" root 2>/dev/null || true
  tc qdisc del dev "$DOWN" root 2>/dev/null || true
}

case "${1:-show}" in
  clean)  reset ;;
  rtt50)  d=25 ;;
  rtt150) d=75 ;;
  loss1)  d=25; l=1 ;;
  loss2)  d=25; l=2 ;;
  loss5)  d=25; l=5 ;;
  custom) d=$(( ${RTT_MS:?set RTT_MS} / 2 )); l=${LOSS_PCT:-0} ;;
  show)   ;;
  *) echo "unknown profile: $1"; exit 1 ;;
esac

if [ -n "$d" ]; then
  reset
  tc qdisc add dev "$UP" root netem delay "${d}ms" limit "$LIMIT"
  tc qdisc add dev "$DOWN" root netem delay "${d}ms" loss "${l}%" limit "$LIMIT"
fi

echo "== $UP (toward server)"; tc -s qdisc show dev "$UP"
echo "== $DOWN (toward client)"; tc -s qdisc show dev "$DOWN"
