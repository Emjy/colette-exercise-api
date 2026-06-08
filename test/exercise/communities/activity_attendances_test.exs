defmodule Exercise.Communities.ActivityAttendancesTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory

  alias Exercise.Communities.ActivityAttendance
  alias Exercise.Communities.ActivityAttendances
  alias Exercise.Errors.DeregisterFromActivityError
  alias Exercise.Repo

  describe "register_to_activity/2" do
    test "creates an attendance" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 5)

      assert {:ok, attendance} = ActivityAttendances.register_to_activity(user, activity)
      assert attendance.user_id == user.id
      assert ActivityAttendances.attendance_count(activity) == 1
    end

    test "a second registration errors on the unique constraint" do
      user = insert(:user)
      activity = insert(:activity)

      assert {:ok, _} = ActivityAttendances.register_to_activity(user, activity)
      assert {:error, changeset} = ActivityAttendances.register_to_activity(user, activity)
      assert %{user_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "rejects registration when the activity is full" do
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      assert {:error, changeset} =
               ActivityAttendances.register_to_activity(insert(:user), activity)

      assert %{base: ["activity is full"]} = errors_on(changeset)
    end

    test "a member can register again after leaving" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 5)
      {:ok, _} = ActivityAttendances.register_to_activity(user, activity)
      {:ok, _} = ActivityAttendances.unregister_from_activity(user, activity)

      assert {:ok, _} = ActivityAttendances.register_to_activity(user, activity)
      assert ActivityAttendances.attendance_count(activity) == 1
    end
  end

  describe "unregister_from_activity/2" do
    test "soft-deletes the attendance: keeps the row, drops the count" do
      user = insert(:user)
      activity = insert(:activity)
      {:ok, attendance} = ActivityAttendances.register_to_activity(user, activity)

      assert {:ok, deleted} = ActivityAttendances.unregister_from_activity(user, activity)
      assert deleted.deleted_at
      assert ActivityAttendances.attendance_count(activity) == 0
      # the row still exists — soft delete, not a hard delete
      assert Repo.get(ActivityAttendance, attendance.id)
    end

    test "returns a DeregisterFromActivityError when there is no active attendance" do
      activity = insert(:activity)

      assert {:error, %DeregisterFromActivityError{activity_id: activity_id}} =
               ActivityAttendances.unregister_from_activity(insert(:user), activity)

      assert activity_id == activity.id
    end
  end

  describe "attendee_count column (DB trigger)" do
    test "is kept in sync as members register and leave" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 5)

      {:ok, _} = ActivityAttendances.register_to_activity(user, activity)
      assert Repo.reload(activity).attendee_count == 1

      {:ok, _} = ActivityAttendances.unregister_from_activity(user, activity)
      assert Repo.reload(activity).attendee_count == 0
    end
  end
end
