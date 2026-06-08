defmodule Exercise.Communities.ActivityAttendances do
  @moduledoc """
  The ActivityAttendances context: attendance writes (register / unregister) and
  counts. The web layer goes through `Exercise.Communities` — never `Repo` or a
  query module directly.
  """
  alias Exercise.Communities.Activity
  alias Exercise.Communities.ActivityAttendance
  alias Exercise.Communities.ActivityAttendances.Query
  alias Exercise.Communities.Events
  alias Exercise.Errors
  alias Exercise.Repo

  @doc "Counts the active (non-soft-deleted) attendances for an activity."
  def attendance_count(%Activity{id: id}) do
    Query.base()
    |> Query.with_activity_id(id)
    |> Query.deleted(false)
    |> Repo.aggregate(:count)
  end

  @doc """
  Registers a member to an activity.

  Returns `{:ok, attendance}` or `{:error, changeset}`. A full activity surfaces as a
  `:base` ("activity is full") changeset error and a duplicate as a unique-constraint
  error; the web layer turns either into a `ValidationError`. Publishes `AttendanceCreated`.
  """
  def register_to_activity(user, activity) do
    %ActivityAttendance{}
    |> ActivityAttendance.changeset(%{user_id: user.id, activity_id: activity.id})
    |> Repo.insert(success_event: Events.AttendanceCreated, event_opts: [])
  end

  @doc """
  Unregisters a member from an activity by **soft-deleting** the attendance
  (stamping `deleted_at`); the row is kept for history.

  Returns `{:error, %DeregisterFromActivityError{}}` or `{:ok, attendance}`.
  Publishes `AttendanceDeleted` (a freed seat — what the waiting list reacts to).
  """
  def unregister_from_activity(user, activity) do
    Query.base()
    |> Query.with_user_id(user.id)
    |> Query.with_activity_id(activity.id)
    |> Query.deleted(false)
    |> Repo.one()
    |> case do
      nil ->
        {:error, Errors.DeregisterFromActivityError.new(activity_id: activity.id)}

      attendance ->
        attendance
        |> ActivityAttendance.delete_changeset()
        |> Repo.update(success_event: Events.AttendanceDeleted, event_opts: [])
    end
  end
end
