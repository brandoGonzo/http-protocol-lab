certs:
	mkcert -install && mkcert -cert-file certs/cert.pem -key-file certs/key.pem localhost server 127.0.0.1

build:
	go build -o bin/server ./server/cmd/server
	go build -o bin/client ./client/cmd/client

lab-up:
	docker compose -f lab/docker-compose.yml up -d --build

lab-down:
	docker compose -f lab/docker-compose.yml down

.PHONY: certs build lab-up lab-down
