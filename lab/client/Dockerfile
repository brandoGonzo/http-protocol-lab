FROM alpine/curl-http3
USER root
RUN apk add --no-cache iproute2 iputils ethtool
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
