# colette-exercise-api — Runbook

A small Phoenix + Absinthe (GraphQL) API mirroring Colette's stack: Ecto/PostGIS,
`ex_event_bus`, Oban, Dataloader. You extend it with an **activity waiting list**.

## Setup

    docker compose up -d   # start Postgres + PostGIS (same image as CI)
    make setup             # deps + create/migrate db + seed

`make setup` connects to Postgres at `postgres:postgres@localhost:5432` (see
`config/dev.exs` / `config/test.exs`); the bundled `docker-compose.yml` provides exactly
that. `make db.up` / `make db.down` wrap compose up/down.

**Bring your own Postgres?** Fine — just make sure it has the **PostGIS** extension and
those credentials, and skip `docker compose up`. Set `POSTGRES_PORT` to remap the host
port if 5432 is already taken.

## Run

    mix phx.server    # GraphQL endpoint: http://localhost:4000/api
                      # Playground:       http://localhost:4000/graphiql

## Auth

Send `Authorization: Bearer <user-id>`. For this exercise the bearer token *is* the
user id (no JWT). Seeded users include `organiser@example.com` and `member1..12@example.com`.

## Quality gate (run this yourself before submitting)

    make check        # mix format --check-formatted && mix credo --strict && mix test

There are deliberately **no pre-commit hooks** — keeping the code formatted, linted,
and tested is part of the exercise.

## Where things live

- `lib/exercise/communities.ex` — context API (register/unregister; publishes domain events)
- `lib/exercise/communities/` — `Activity`, `ActivityAttendance`, `Events`
- `lib/exercise/event_bus.ex` + `Repo` wrapper — events publish on successful writes
- `lib/exercise_web/schema.ex` + `schema/` + `resolvers/` — the GraphQL API
- `priv/repo/seeds.exs` — full / open / draft / archived activities
