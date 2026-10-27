# server

Single Go process serving identical content over HTTP/1.1 + HTTP/2 (TCP :443, ALPN-selectable) and HTTP/3 (UDP :443 via quic-go). Emits qlog.

- `cmd/server/` entrypoint
- `internal/handler/` shared http.Handler + test asset routes
