defmodule Exercise.Communities.ActivityAttendances.QueryTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory
  import Ecto.Query

  alias Exercise.Communities.ActivityAttendances.Query
  alias Exercise.Repo

  describe "with_user_id/2 + with_activity_id/2" do
    test "scope to a user's attendance of an activity" do
      user = insert(:user)
      activity = insert(:activity)
      attendance = insert(:activity_attendance, user: user, activity: activity)
      _other = insert(:activity_attendance, activity: activity)

      ids =
        Query.base()
        |> Query.with_user_id(user.id)
        |> Query.with_activity_id(activity.id)
        |> select([a], a.id)
        |> Repo.all()

      assert ids == [attendance.id]
    end
  end

  describe "deleted/2" do
    test "false keeps active rows; true keeps soft-deleted rows" do
      active = insert(:activity_attendance)
      deleted = insert(:activity_attendance, deleted_at: DateTime.utc_now())

      active_ids = Query.base() |> Query.deleted(false) |> select([a], a.id) |> Repo.all()
      deleted_ids = Query.base() |> Query.deleted(true) |> select([a], a.id) |> Repo.all()

      assert active.id in active_ids
      refute deleted.id in active_ids
      assert deleted.id in deleted_ids
      refute active.id in deleted_ids
    end
  end
end
