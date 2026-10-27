# lab

Docker Compose topology: client <-> router <-> server. tc netem runs on the router's interfaces so impairment never steals CPU from the endpoints.

- `netem/` profile scripts (clean, 50ms, 150ms, loss-1, loss-2, loss-5)
