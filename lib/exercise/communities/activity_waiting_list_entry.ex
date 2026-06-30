defmodule Exercise.Communities.ActivityWaitingListEntry do
  @moduledoc "A member's place on the waiting list of a full activity."
  use Ecto.Schema

  import Ecto.Changeset

  alias Exercise.Accounts.User
  alias Exercise.Communities.Activities.Query, as: ActivityQuery
  alias Exercise.Communities.Activity
  alias Exercise.Communities.ActivityAttendances.Query, as: AttendanceQuery

  @derive {Jason.Encoder,
           only: [:id, :user_id, :activity_id, :converted_at, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "activity_waiting_list_entries" do
    field :converted_at, :utc_datetime_usec

    belongs_to :user, User
    belongs_to :activity, Activity
    timestamps(type: :utc_datetime_usec)
  end

  @doc "Changeset for joining the waiting list of a full activity."
  def join_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:user_id, :activity_id])
    |> validate_required([:user_id, :activity_id])
    |> unique_constraint([:user_id, :activity_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:activity)
    |> check_activity_full()
    |> check_not_registered()
  end

  @doc "Stamps `converted_at` when the member registers for the activity."
  def convert_changeset(entry) do
    change(entry, converted_at: DateTime.utc_now())
  end

  # Validates that the activity is full at insert time, inside the transaction.
  # We do not lock FOR UPDATE here: the waiting list has no capacity cap, so
  # there is nothing to serialise — the unique index handles concurrent joins.
  defp check_activity_full(changeset) do
    prepare_changes(changeset, fn changeset ->
      activity =
        ActivityQuery.base()
        |> ActivityQuery.with_id(get_field(changeset, :activity_id))
        |> changeset.repo.one()

      if activity && activity.attendee_count < activity.max_attendees do
        add_error(changeset, :base, "activity is not full")
      else
        changeset
      end
    end)
  end

  # Validates that the member is not already registered for the activity.
  defp check_not_registered(changeset) do
    prepare_changes(changeset, fn changeset ->
      already_registered =
        AttendanceQuery.base()
        |> AttendanceQuery.with_user_id(get_field(changeset, :user_id))
        |> AttendanceQuery.with_activity_id(get_field(changeset, :activity_id))
        |> AttendanceQuery.deleted(false)
        |> changeset.repo.exists?()

      if already_registered do
        add_error(changeset, :base, "already registered to this activity")
      else
        changeset
      end
    end)
  end
end
