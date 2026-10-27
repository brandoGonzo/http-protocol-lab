FROM alpine:3.20
RUN apk add --no-cache iproute2 iproute2-tc tcpdump ethtool
COPY netem.sh /usr/local/bin/netem
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/netem
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
