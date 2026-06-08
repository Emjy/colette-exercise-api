# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :exercise,
  ecto_repos: [Exercise.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :exercise, ExerciseWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ExerciseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Exercise.PubSub,
  live_view: [signing_salt: "HOdh9L/C"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# PostGIS custom Postgrex types
config :exercise, Exercise.Repo, types: Exercise.PostgresTypes

# Application Oban (candidate workers run here, e.g. NotifyWaitingListMember)
config :exercise, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.PG,
  repo: Exercise.Repo,
  queues: [notifications: 10]

# ex_event_bus runs its own Oban instance to dispatch domain events to handlers
config :exercise, Exercise.EventBus,
  oban: [
    engine: Oban.Engines.Basic,
    notifier: Oban.Notifiers.PG,
    repo: Exercise.Repo,
    queues: [ex_event_bus: 5]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
