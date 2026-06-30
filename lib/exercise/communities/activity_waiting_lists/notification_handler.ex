defmodule Exercise.Communities.ActivityWaitingLists.NotificationHandler do
  @moduledoc """
  Reacts to AttendanceDeleted (a freed seat) and enqueues one notification job
  per member currently on the activity's waiting list.

  Runs asynchronously as an Oban job on the event bus's queue, so it never
  blocks the request that freed the seat.
  """
  use ExEventBus.EventHandler,
    ex_event_bus: Exercise.EventBus,
    events: ["Elixir.Exercise.Communities.Events.AttendanceDeleted"]

  alias Exercise.Communities.ActivityWaitingListEntries.Query
  alias Exercise.Communities.ActivityWaitingLists.NotificationWorker
  alias Exercise.Repo

  @impl ExEventBus.EventHandler
  def handle_event(%{aggregate: %{"activity_id" => activity_id}}) do
    Query.base()
    |> Query.with_activity_id(activity_id)
    |> Query.unconverted()
    |> Repo.all()
    |> Enum.each(fn entry ->
      %{user_id: entry.user_id, activity_id: entry.activity_id}
      |> NotificationWorker.new()
      |> Oban.insert()
    end)

    :ok
  end
end
