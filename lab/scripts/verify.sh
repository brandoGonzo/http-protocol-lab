#!/usr/bin/env bash
set -euo pipefail
DC="docker compose -f lab/docker-compose.yml"
PROFILE="${1:-rtt50}"

echo "[0] applying netem profile: $PROFILE"
$DC exec -T router netem "$PROFILE" > /dev/null

echo "[1] route from client to server (expect: via 10.10.1.254)"
$DC exec -T client ip route get 10.10.2.10

echo "[2] ping (expect ttl=63 = one routed hop, rtt ~ profile RTT)"
$DC exec -T client ping -c 1 server | sed -n 2p
$DC exec -T client ping -c 20 -q server | tail -2

echo "[3] protocol checks against https://server/1mb.bin"
for p in http1.1 http2 http3-only; do
  $DC exec -T client curl -sk --$p -o /dev/null \
    -w "$p -> HTTP/%{http_version}  connect=%{time_connect}s  tls=%{time_appconnect}s  ttfb=%{time_starttransfer}s  total=%{time_total}s\n" \
    https://server/1mb.bin
done

echo "[4] router qdisc counters (sent / dropped)"
$DC exec -T router netem show
