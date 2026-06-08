defmodule Exercise.Communities.ActivityAttendances.Query do
  @moduledoc """
  Composable Ecto queries for activity attendances. Scopes take a queryable as their
  first argument and return a queryable, so they pipe together.
  """
  import Ecto.Query

  alias Exercise.Communities.ActivityAttendance

  @doc "The base queryable for activity attendances."
  def base, do: ActivityAttendance

  @doc "Scope: attendances for a given activity."
  def with_activity_id(queryable, activity_id) do
    where(queryable, [a], a.activity_id == ^activity_id)
  end

  @doc "Scope: attendances for a given user."
  def with_user_id(queryable, user_id) do
    where(queryable, [a], a.user_id == ^user_id)
  end

  @doc "Scope by soft-delete state — `deleted(q, false)` keeps only active rows."
  def deleted(queryable, true), do: where(queryable, [a], not is_nil(a.deleted_at))
  def deleted(queryable, false), do: where(queryable, [a], is_nil(a.deleted_at))
end
