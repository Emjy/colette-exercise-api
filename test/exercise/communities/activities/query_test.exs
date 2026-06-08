defmodule Exercise.Communities.Activities.QueryTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory
  import Ecto.Query

  alias Exercise.Communities.Activities.Query
  alias Exercise.Repo

  describe "visible/1" do
    test "excludes archived and unpublished activities" do
      visible = insert(:activity)
      _archived = insert(:activity, archived_at: DateTime.utc_now())
      _draft = insert(:activity, published_at: nil)

      ids = Query.visible() |> select([a], a.id) |> Repo.all()
      assert ids == [visible.id]
    end

    test "is composable with other scopes" do
      visible = insert(:activity, slug: "yoga")
      _other = insert(:activity, slug: "pottery")

      ids =
        Query.base()
        |> Query.visible()
        |> Query.with_slug("yoga")
        |> select([a], a.id)
        |> Repo.all()

      assert ids == [visible.id]
    end
  end

  describe "with_slug/2" do
    test "filters by slug" do
      activity = insert(:activity, slug: "find-me")
      _other = insert(:activity, slug: "skip-me")

      ids = Query.base() |> Query.with_slug("find-me") |> select([a], a.id) |> Repo.all()
      assert ids == [activity.id]
    end
  end

  describe "with_available_seats/2" do
    test "true keeps activities with a free seat; false keeps full ones" do
      open = insert(:activity, max_attendees: 2)
      full = insert(:activity, max_attendees: 1)
      # the trigger bumps full.attendee_count to 1, making it full
      insert(:activity_attendance, activity: full)

      open_ids =
        Query.base() |> Query.with_available_seats(true) |> select([a], a.id) |> Repo.all()

      full_ids =
        Query.base() |> Query.with_available_seats(false) |> select([a], a.id) |> Repo.all()

      assert open.id in open_ids
      refute full.id in open_ids
      assert full.id in full_ids
      refute open.id in full_ids
    end
  end
end
