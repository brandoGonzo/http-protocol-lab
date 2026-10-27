# lab

Three containers on two isolated bridge networks. All client <-> server traffic is forced through the router, where `tc netem` shapes it. Impairment never runs on the endpoints, so it never steals their CPU.

| Container | IP | Role |
|---|---|---|
| client | 10.10.1.10 | Probe: curl with HTTP/3 (later: Go timing client + h2load) |
| router | 10.10.1.254 / 10.10.2.254 | IP forwarding + netem |
| server | 10.10.2.10 | Stub: Caddy serving h1/h2/h3 on :443 (later: our Go server) |

## Netem profiles

Delay is split evenly across both directions. Loss applies to the downlink (server -> client), where the bulk data flows.

| Profile | RTT | Downlink loss |
|---|---|---|
| clean | ~0 | 0% |
| rtt50 | 50 ms | 0% |
| rtt150 | 150 ms | 0% |
| loss1 / loss2 / loss5 | 50 ms | 1 / 2 / 5% |
| custom | `RTT_MS` | `LOSS_PCT` |

## Usage

```sh
make lab-up
make lab-verify PROFILE=rtt50
make netem PROFILE=loss2
make lab-shell-router
make lab-down
```

## What a healthy lab looks like (rtt50)

- `ip route get` shows `via 10.10.1.254`
- ping shows `ttl=63` and avg RTT ~50 ms
- curl reports HTTP/1.1, HTTP/2, and HTTP/3 respectively
- `tls=` is ~2 RTT (~100 ms) for h1/h2 and ~1 RTT (~50 ms) for h3
- router qdisc counters increase; `dropped` increases under loss profiles

## Host requirements

The `sch_netem` kernel module must be available on the Docker host (Linux: `sudo modprobe sch_netem`; Docker Desktop's VM normally ships it).
