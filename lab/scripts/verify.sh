#!/usr/bin/env bash
# usage: N=10 bash lab/scripts/verify.sh <profile>
# Every curl run is a fresh process = cold connection (no reuse, no 0-RTT).
# Compare tls= and ttfb= across protocols; curl's connect time is not comparable for QUIC.
set -euo pipefail
DC="docker compose -f lab/docker-compose.yml"
PROFILE="${1:-rtt50}"
N="${N:-10}"
URL="https://server/1mb.bin"

apply() {
  $DC exec -T -e RTT_MS="${RTT_MS:-}" -e LOSS_PCT="${LOSS_PCT:-}" router netem "$PROFILE" > /dev/null
}

median() {
  sort -n | awk '{a[NR]=$1} END{ if(NR==0){print "n/a"; exit} m=(NR%2)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2; printf "%.3f", m }'
}

echo "[0] applying netem profile: $PROFILE (N=$N)"
apply

echo "[1] route from client to server (expect: via 10.10.1.254)"
$DC exec -T client ip route get 10.10.2.10

echo "[2] ping (expect ttl=63 = one routed hop, rtt ~ profile RTT)"
$DC exec -T client ping -c 1 server | sed -n 2p
$DC exec -T client ping -c 20 -q server | tail -2

if [[ "$PROFILE" == loss* || "${LOSS_PCT:-0}" != "0" ]]; then
  echo "[2b] loss calibration: 500 pings (expect ~profile loss %)"
  $DC exec -T client ping -c 500 -i 0.01 -q server | grep 'packet loss' || true
  apply
fi

echo "[3] protocol checks against $URL, median of $N cold runs"
for p in http1.1 http2 http3-only; do
  f=$(mktemp)
  for _ in $(seq "$N"); do
    $DC exec -T client curl -sk --$p -o /dev/null \
      -w "%{time_appconnect} %{time_starttransfer} %{time_total} %{http_version}\n" "$URL" >> "$f"
  done
  ver=$(awk 'END{print $4}' "$f")
  tls=$(cut -d' ' -f1 "$f" | median)
  ttfb=$(cut -d' ' -f2 "$f" | median)
  tot=$(cut -d' ' -f3 "$f" | median)
  mn=$(cut -d' ' -f3 "$f" | sort -n | head -1)
  mx=$(cut -d' ' -f3 "$f" | sort -n | tail -1)
  printf "%-11s HTTP/%-3s tls=%ss  ttfb=%ss  total=%ss  (total min %s / max %s)\n" "$p" "$ver" "$tls" "$ttfb" "$tot" "$mn" "$mx"
  rm -f "$f"
done

echo "[4] router qdisc counters for step [3] only"
out=$($DC exec -T router netem show)
echo "$out"
echo "$out" | awk '/^==/{dev=$2} /Sent/{s=$4; d=$7; gsub(/,/,"",d); if (s+d>0) printf "%s: dropped %d of %d pkts (%.2f%%)\n", dev, d, s+d, 100*d/(s+d)}'
