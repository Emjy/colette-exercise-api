# Colette exercise — docs (backend)

The conventions for this take-home. **Match them exactly — they override default habits.**
You build **one** feature end to end (backend + frontend); your task is under
[`DOMAIN.md` → "Your task"](DOMAIN.md), which links to your task in [`tasks/`](tasks/).

- [`ENGINEERING_GUIDE.md`](ENGINEERING_GUIDE.md) — architecture, Elixir style, changesets,
  soft deletes, domain events, Oban, testing.
- [`DOMAIN.md`](DOMAIN.md) — the shared data model (User, Activity, ActivityAttendance,
  the visibility scope, the capacity check); links to your task.
- [`GRAPHQL.md`](GRAPHQL.md) — Absinthe resolvers, auth, the `Exercise.Errors` error model,
  Dataloader (no N+1).
- [`API.md`](API.md) — frontend conventions and how the two repos talk.
- [`tasks/`](tasks/) — `waiting-list.md`, the feature to build.

## Repo layout

This is the **backend** repo (`colette-exercise-api`). Code paths in these docs — `lib/…`,
`priv/…`, `config/…`, `test/…` — are in **this** repo. Frontend paths in `API.md` and the
tasks — `app/…` and `~/…` imports — refer to the sibling **`../colette-exercise-web`** repo.

## Quality gate

```bash
make check   # mix format --check-formatted && mix credo --strict && mix test
```

The frontend has its own gate (`bun run check`, in `../colette-exercise-web`). Both must be
green before you submit.
