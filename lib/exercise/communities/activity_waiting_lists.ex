defmodule Exercise.Communities.ActivityWaitingLists do
  @moduledoc """
  The ActivityWaitingLists context: joining a full activity's waiting list and
  converting entries when a member subsequently registers.

  The web layer goes through `Exercise.Communities` — never `Repo` or a query
  module directly.
  """
  alias Exercise.Accounts.User
  alias Exercise.Communities.Activity
  alias Exercise.Communities.ActivityWaitingListEntries.Query
  alias Exercise.Communities.ActivityWaitingListEntry
  alias Exercise.Communities.Events
  alias Exercise.Repo

  @doc """
  Adds a member to the waiting list of a full activity.

  Returns `{:ok, entry}` or `{:error, changeset}`. Fails (via changeset errors)
  if the activity is not full, the member is already registered, or already on
  the waiting list. Publishes `WaitingListEntryCreated` on success.
  """
  def join_waiting_list(%User{} = user, %Activity{} = activity) do
    %ActivityWaitingListEntry{}
    |> ActivityWaitingListEntry.join_changeset(%{user_id: user.id, activity_id: activity.id})
    |> Repo.insert(success_event: Events.WaitingListEntryCreated, event_opts: [])
  end

  @doc """
  Stamps `converted_at` on the member's active waiting list entry when they
  register for the activity. Returns `{:ok, nil}` if no active entry exists
  (the member was not on the waiting list — that's fine).
  """
  def convert_entry(%User{} = user, %Activity{} = activity) do
    Query.base()
    |> Query.with_user_id(user.id)
    |> Query.with_activity_id(activity.id)
    |> Query.unconverted()
    |> Repo.one()
    |> case do
      nil -> {:ok, nil}
      entry -> entry |> ActivityWaitingListEntry.convert_changeset() |> Repo.update()
    end
  end
end
