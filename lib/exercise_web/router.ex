defmodule ExerciseWeb.Router do
  use ExerciseWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug ExerciseWeb.Context
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug, schema: ExerciseWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: ExerciseWeb.Schema,
      interface: :playground
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:exercise, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ExerciseWeb.Telemetry
    end
  end
end
