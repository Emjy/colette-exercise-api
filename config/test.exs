import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :exercise, Exercise.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "exercise_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :exercise, ExerciseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "xfYmb4z9m6pWFjFHNdUxr2QLhJh5aFrQXHktlGd+YPpqr01bQ7Q3SncKESZI2PC2",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Oban + event bus: enqueue jobs but don't run them automatically in tests.
# Use Oban.Testing.assert_enqueued and Exercise.EventBus.execute_events/0 to drive handlers.
config :exercise, Oban, testing: :manual
config :exercise, Exercise.EventBus, oban: [testing: :manual]
