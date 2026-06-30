defmodule Exercise.Communities.Events do
  @moduledoc "Community domain events, published by the Repo wrapper on successful writes."
  use ExEventBus.Event

  defevents([
    AttendanceCreated,
    AttendanceDeleted,
    WaitingListEntryCreated
  ])
end
