# http-protocol-lab

A Go + Docker test bed that serves identical content over **HTTP/1.1**, **HTTP/2**, and **HTTP/3 (QUIC)**, then measures what actually changes between them under controlled latency, jitter, and packet loss.

## Architecture

```mermaid
flowchart LR
  subgraph Host[Docker host]
    subgraph ClientNet[client_net]
      C[client container<br/>Go timing client + h2load]
    end
    R[router container<br/>NET_ADMIN, tc netem<br/>latency, jitter, loss]
    subgraph ServerNet[server_net]
      S[server container<br/>Go server]
    end
  end
  C -->|TCP 443 ALPN http/1.1 or h2| R
  C -->|UDP 443 QUIC h3| R
  R --> S
  S --> H1[TCP listener<br/>HTTP/1.1 + HTTP/2]
  S --> H3[QUIC listener<br/>quic-go HTTP/3]
  H1 --> HD[shared http.Handler<br/>test assets]
  H3 --> HD
  E[experiments YAML] --> RUN[runner]
  RUN --> C
  C --> RES[results JSON]
  S --> Q[qlog + pcap]
  RES --> D[dashboard on GitHub Pages]
  Q --> D
```

## Handshakes: HTTP/1.1 vs HTTP/2 vs HTTP/3

```mermaid
sequenceDiagram
  participant Client
  participant Server
  Note over Client,Server: HTTP/1.1 over TCP + TLS 1.3 (2 RTT to first byte)
  Client->>Server: TCP SYN
  Server-->>Client: SYN-ACK
  Client->>Server: ACK + TLS ClientHello (ALPN http/1.1)
  Server-->>Client: ServerHello, Cert, Finished
  Client->>Server: Finished + GET /a
  Server-->>Client: 200 /a
  Note over Client,Server: HTTP/2 over TCP + TLS 1.3 (2 RTT to first byte)
  Client->>Server: TCP SYN
  Server-->>Client: SYN-ACK
  Client->>Server: ACK + TLS ClientHello (ALPN h2)
  Server-->>Client: ServerHello, Cert, Finished
  Client->>Server: Preface + SETTINGS + HEADERS streams 1,3,5 (HPACK)
  Server-->>Client: DATA interleaved on streams 1,3,5
  Note over Client,Server: One lost TCP packet stalls ALL streams (HOL blocking)
  Note over Client,Server: HTTP/3 over QUIC (1 RTT, 0-RTT on resume)
  Client->>Server: QUIC Initial (TLS ClientHello, ALPN h3)
  Server-->>Client: Initial + Handshake (ServerHello, Cert, Finished)
  Client->>Server: Handshake Finished + HEADERS streams 0,4,8 (QPACK)
  Server-->>Client: STREAM frames, independent per stream
  Client->>Server: [resumed] 0-RTT GET with session ticket
  Server-->>Client: 200 in the first round trip
```

Editable versions live in Lucid; sources are in [`docs/diagrams/`](docs/diagrams/).

## Repo layout

| Path | Purpose |
|---|---|
| `server/` | Go server: TCP (h1/h2) + QUIC (h3) listeners, shared handler, qlog |
| `client/` | Go timing client (DNS, connect, TLS, TTFB, total) |
| `lab/` | Docker Compose topology + netem profiles |
| `experiments/` | YAML experiment definitions |
| `results/` | Summary JSON consumed by the dashboard |
| `dashboard/` | Static charts site (GitHub Pages) |
| `docs/` | Diagrams and write-ups |
| `certs/` | mkcert-generated local TLS certs (gitignored) |

## Planned experiments

| Experiment | Demonstrates |
|---|---|
| 100 small assets, 0% loss, 50 ms RTT | Multiplexing vs HTTP/1.1 connection limits |
| Same at 1-5% loss | TCP head-of-line blocking vs QUIC per-stream loss |
| Cold connect, 150 ms RTT | Handshake round trips |
| 0-RTT resumption | QUIC early data |
| Repeated large headers | HPACK vs QPACK compression |
| Client IP change mid-transfer | QUIC connection migration |
| 100 MB bulk download | Throughput and CPU cost |

## Roadmap

- [ ] M1: Single server speaking h1/h2/h3, verified with curl
- [ ] M2: Netem lab + h2load runner
- [ ] M3: Custom timing client to JSON
- [ ] M4: Dashboard + findings write-ups
- [ ] M5: pcap/qlog visualizations + CI benchmark runs

## Quick start (WIP)

```sh
make certs
make lab-up
```
