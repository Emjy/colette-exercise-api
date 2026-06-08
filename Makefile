.PHONY: setup check test lint format db.up db.down db.reset server

db.up:
	docker compose up -d

db.down:
	docker compose down

setup:
	mix deps.get
	mix ecto.create
	mix ecto.migrate
	mix run priv/repo/seeds.exs

check: lint test

lint:
	mix format --check-formatted
	mix credo --strict

test:
	mix test

format:
	mix format

db.reset:
	mix ecto.reset

server:
	mix phx.server
