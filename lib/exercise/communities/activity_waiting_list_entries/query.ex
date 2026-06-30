defmodule Exercise.Communities.ActivityWaitingListEntries.Query do
  @moduledoc """
  Composable Ecto queries for activity waiting list entries. Scopes take a queryable
  as their first argument and return a queryable, so they pipe together.
  """
  import Ecto.Query

  alias Exercise.Communities.ActivityWaitingListEntry

  @doc "The base queryable for waiting list entries."
  def base, do: ActivityWaitingListEntry

  @doc "Scope: entries for a given activity."
  def with_activity_id(queryable, activity_id) do
    where(queryable, [e], e.activity_id == ^activity_id)
  end

  @doc "Scope: entries for a given user."
  def with_user_id(queryable, user_id) do
    where(queryable, [e], e.user_id == ^user_id)
  end

  @doc "Scope: entries not yet converted to a registration."
  def unconverted(queryable) do
    where(queryable, [e], is_nil(e.converted_at))
  end

  @doc "Composite scope for Dataloader: unconverted entries for a specific user."
  def for_user_unconverted(queryable, user_id) do
    queryable
    |> with_user_id(user_id)
    |> unconverted()
  end
end
