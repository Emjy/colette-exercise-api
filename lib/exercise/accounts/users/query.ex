defmodule Exercise.Accounts.Users.Query do
  @moduledoc """
  Composable Ecto queries for users.
  """
  import Ecto.Query

  alias Exercise.Accounts.User

  @doc "The base queryable for users."
  def base, do: User

  @doc "Scope: non-archived (active) users."
  def active(queryable \\ base()) do
    where(queryable, [u], is_nil(u.archived_at))
  end
end
