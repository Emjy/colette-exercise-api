defmodule Exercise.Communities.Activities.Query do
  @moduledoc """
  Composable Ecto queries for activities. Scopes take a queryable as their first
  argument and return a queryable, so they pipe together.
  """
  import Ecto.Query

  alias Exercise.Communities.Activity

  @doc "The base queryable for activities."
  def base, do: Activity

  @doc "Scope: a single activity by id."
  def with_id(queryable, id) do
    where(queryable, [a], a.id == ^id)
  end

  @doc "Locks the matched rows `FOR UPDATE` — serialises concurrent capacity checks."
  def for_update(queryable) do
    lock(queryable, "FOR UPDATE")
  end

  @doc "Scope: published (publish date in the past) and not archived — visible to members."
  def visible(queryable \\ base()) do
    now = DateTime.utc_now()

    queryable
    |> where([a], not is_nil(a.published_at) and a.published_at <= ^now)
    |> where([a], is_nil(a.archived_at))
  end

  @doc "Scope: a single activity by slug."
  def with_slug(queryable, slug) do
    where(queryable, [a], a.slug == ^slug)
  end

  @doc "Order: soonest first (start time ascending), with id as a stable tie-breaker."
  def order_by_starts_at(queryable \\ base()) do
    order_by(queryable, [a], asc: a.starts_at, asc: a.id)
  end

  @doc """
  Scope by seat availability, comparing the trigger-maintained `attendee_count`
  against `max_attendees`. `with_available_seats(q, true)` keeps activities with a
  free seat; `false` keeps full ones.
  """
  def with_available_seats(queryable, true) do
    where(queryable, [a], a.attendee_count < a.max_attendees)
  end

  def with_available_seats(queryable, false) do
    where(queryable, [a], a.attendee_count >= a.max_attendees)
  end
end
