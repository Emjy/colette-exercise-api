defmodule Exercise.Accounts.Users do
  @moduledoc """
  This module handles users.
  """
  alias Exercise.Accounts.Users.Query
  alias Exercise.Errors
  alias Exercise.Repo

  @doc "Fetches a non-archived user by id. Returns `{:ok, user}` or `{:error, %NotFoundError{}}`."
  def get_user(id) do
    Query.active()
    |> Repo.get(id)
    |> case do
      nil -> {:error, Errors.NotFoundError.new(type: "User", fields: %{id: id})}
      user -> {:ok, user}
    end
  end
end
