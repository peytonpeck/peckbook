envfile := ./.env

.PHONY: help install db-create db-down db-logs db-reset sql server client ngrok

TARGET_MAX_CHAR_NUM=20

## Show help
help:
	@echo ''
	@echo 'Usage:'
	@echo '  make <target>'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z_0-9-]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  %-$(TARGET_MAX_CHAR_NUM)s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Install dependencies for client and server
install: $(envfile)
	cd client && npm install
	cd server && npm install

## Start the Docker Postgres database and initialize tables on its first run
db-create:
	docker compose up -d --wait postgres

## Stop the Docker Postgres database (data is retained)
db-down:
	docker compose down

## Follow Docker Postgres logs
db-logs:
	docker compose logs -f postgres

## Delete all Docker Postgres data, then recreate the database and tables
db-reset:
	docker compose down -v
	docker compose up -d --wait postgres

## Start an interactive psql session in the Docker Postgres container
sql:
	docker compose exec postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

## Start the server (port 5001)
server: $(envfile)
	cd server && npm start

## Start the client (port 3001)
client: $(envfile)
	cd client && npm start

## Start ngrok tunnel to expose server for webhooks
ngrok:
	ngrok http 5001

$(envfile):
	@echo "Error: .env file does not exist! Copy .env.template to .env and fill in your keys."
	@exit 1
