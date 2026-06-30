defmodule Exercise.Communities.ActivityAttendance do
  @moduledoc "A member's registration to an activity."
  use Ecto.Schema

  import Ecto.Changeset

  alias Exercise.Accounts.User
  alias Exercise.Communities.Activities.Query
  alias Exercise.Communities.Activity

  @derive {Jason.Encoder,
           only: [:id, :user_id, :activity_id, :deleted_at, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "activity_attendances" do
    field :deleted_at, :utc_datetime_usec

    belongs_to :user, User
    belongs_to :activity, Activity
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(attendance, attrs) do
    attendance
    |> cast(attrs, [:user_id, :activity_id])
    |> validate_required([:user_id, :activity_id])
    |> unique_constraint([:user_id, :activity_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:activity)
    |> check_capacity()
  end

  # Capacity is enforced at insert time, inside the transaction (via prepare_changes),
  # so the check can't act on a stale in-memory count.
  defp check_capacity(changeset) do
    prepare_changes(changeset, fn changeset ->
      # Lock the activity row so concurrent registrations serialise here — without this,
      # parallel inserts all read the same count and overbook the activity.
      activity =
        Query.base()
        |> Query.with_id(get_field(changeset, :activity_id))
        |> Query.for_update()
        |> changeset.repo.one()

      if activity && activity.attendee_count >= activity.max_attendees do
        add_error(changeset, :base, "activity is full")
      else
        changeset
      end
    end)
  end

  @doc "Soft-delete: stamps `deleted_at` (leaving an activity frees the seat)."
  def delete_changeset(attendance) do
    change(attendance, deleted_at: DateTime.utc_now())
  end
end
