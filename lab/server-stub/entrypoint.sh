#!/bin/sh
set -e
ip route replace 10.10.1.0/24 via 10.10.2.254
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
