defmodule ExerciseWeb.Context do
  @moduledoc "Absinthe context plug: resolves the bearer token to a current_user."
  @behaviour Plug

  import Plug.Conn

  alias Exercise.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Accounts.get_user(token) do
      Absinthe.Plug.put_options(conn, context: %{current_user: user})
    else
      _ -> conn
    end
  end
end
