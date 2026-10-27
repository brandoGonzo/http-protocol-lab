FROM caddy:2-alpine
RUN apk add --no-cache iproute2 \
 && mkdir -p /srv \
 && echo "http-protocol-lab stub" > /srv/index.html \
 && head -c 1048576 /dev/urandom > /srv/1mb.bin
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
