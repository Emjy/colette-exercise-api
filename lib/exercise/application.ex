defmodule Exercise.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExerciseWeb.Telemetry,
      Exercise.Repo,
      {DNSCluster, query: Application.get_env(:exercise, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Exercise.PubSub},
      Exercise.EventBus,
      {Oban, Application.fetch_env!(:exercise, Oban)},
      # Start to serve requests, typically the last entry
      ExerciseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exercise.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExerciseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
