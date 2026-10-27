#!/bin/sh
set -e
ip route replace 10.10.2.0/24 via 10.10.1.254
exec sleep infinity
