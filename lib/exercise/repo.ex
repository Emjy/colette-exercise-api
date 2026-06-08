defmodule Exercise.Repo do
  use Ecto.Repo,
    otp_app: :exercise,
    adapter: Ecto.Adapters.Postgres

  use ExEventBus.EctoRepoWrapper, ex_event_bus: Exercise.EventBus
end
