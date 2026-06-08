defmodule ExerciseWeb.Schema.Queries.ActivitiesTest do
  @moduledoc false
  use ExerciseWeb.ConnCase, async: true
  use ExerciseWeb.GqlCase

  import Exercise.Factory

  @moduletag :gql

  load_gql_file("Activities.gql")

  describe "Activities.gql" do
    test "returns only visible activities with creator + count" do
      visible = insert(:activity, title: "Visible")
      insert(:activity, archived_at: DateTime.utc_now())
      insert(:activity_attendance, activity: visible)

      data = query_gql()

      assert %{"data" => %{"activities" => [activity]}} = data
      assert activity["title"] == "Visible"
      assert activity["attendanceCount"] == 1
      assert activity["creator"]["name"]
    end

    test "viewerIsRegistered is per-activity correct for the current viewer (batched)" do
      registered = insert(:activity, title: "Registered")
      _other = insert(:activity, title: "Other")
      viewer = insert(:user)
      insert(:activity_attendance, activity: registered, user: viewer)

      by_title =
        query_gql(current_user: viewer)
        |> get_in(["data", "activities"])
        |> Map.new(fn a -> {a["title"], a["viewerIsRegistered"]} end)

      assert by_title == %{"Registered" => true, "Other" => false}
    end

    test "viewerIsRegistered is false for a different signed-in user and for anonymous viewers" do
      activity = insert(:activity)
      insert(:activity_attendance, activity: activity, user: insert(:user))

      assert [%{"viewerIsRegistered" => false}] =
               get_in(query_gql(current_user: insert(:user)), ["data", "activities"])

      assert [%{"viewerIsRegistered" => false}] =
               get_in(query_gql(), ["data", "activities"])
    end

    test "viewerIsRegistered is false once the viewer has left (soft-deleted attendance)" do
      activity = insert(:activity)
      viewer = insert(:user)

      insert(:activity_attendance,
        activity: activity,
        user: viewer,
        deleted_at: DateTime.utc_now()
      )

      assert [%{"viewerIsRegistered" => false}] =
               get_in(query_gql(current_user: viewer), ["data", "activities"])
    end
  end
end
