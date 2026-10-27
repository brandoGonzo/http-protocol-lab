FROM alpine:3.20
RUN apk add --no-cache iproute2 iproute2-tc tcpdump
COPY netem.sh /usr/local/bin/netem
RUN chmod +x /usr/local/bin/netem
CMD ["sleep", "infinity"]
