COMPOSE = docker compose -f lab/docker-compose.yml
PROFILE ?= rtt50
N ?= 10

certs:
	mkcert -install && mkcert -cert-file certs/cert.pem -key-file certs/key.pem localhost server 127.0.0.1

build:
	go build -o bin/server ./server/cmd/server
	go build -o bin/client ./client/cmd/client

lab-up:
	$(COMPOSE) up -d --build

lab-down:
	$(COMPOSE) down

netem:
	$(COMPOSE) exec router netem $(PROFILE)

lab-verify:
	N=$(N) bash lab/scripts/verify.sh $(PROFILE)

lab-shell-%:
	$(COMPOSE) exec $* sh

.PHONY: certs build lab-up lab-down netem lab-verify
