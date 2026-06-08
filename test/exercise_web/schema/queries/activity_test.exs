defmodule ExerciseWeb.Schema.Queries.ActivityTest do
  @moduledoc false
  use ExerciseWeb.ConnCase, async: true
  use ExerciseWeb.GqlCase

  import Exercise.Factory

  @moduletag :gql

  load_gql_file("Activity.gql")

  describe "Activity.gql" do
    test "returns a visible activity by slug with creator + count" do
      activity =
        insert(:activity,
          slug: "open-pottery",
          title: "Open Pottery",
          description: "Throw a bowl"
        )

      insert(:activity_attendance, activity: activity)

      data = query_gql(variables: %{slug: "open-pottery"})

      assert %{"data" => %{"activity" => found}} = data
      assert found["title"] == "Open Pottery"
      assert found["slug"] == "open-pottery"
      assert found["description"] == "Throw a bowl"
      assert found["attendanceCount"] == 1
      assert found["remainingSpots"] == activity.max_attendees - 1
      assert found["creator"]["name"]
    end

    test "viewerIsRegistered is true for the registered viewer, false for others and anonymous" do
      activity = insert(:activity, slug: "pottery")
      viewer = insert(:user)
      insert(:activity_attendance, activity: activity, user: viewer)

      assert %{"data" => %{"activity" => %{"viewerIsRegistered" => true}}} =
               query_gql(current_user: viewer, variables: %{slug: "pottery"})

      assert %{"data" => %{"activity" => %{"viewerIsRegistered" => false}}} =
               query_gql(current_user: insert(:user), variables: %{slug: "pottery"})

      assert %{"data" => %{"activity" => %{"viewerIsRegistered" => false}}} =
               query_gql(variables: %{slug: "pottery"})
    end

    test "participants lists the registered members, excluding those who have left" do
      activity = insert(:activity, slug: "pottery")
      alice = insert(:user, name: "Alice")
      bob = insert(:user, name: "Bob")
      carol = insert(:user, name: "Carol")

      insert(:activity_attendance, activity: activity, user: alice)
      insert(:activity_attendance, activity: activity, user: bob)

      insert(:activity_attendance,
        activity: activity,
        user: carol,
        deleted_at: DateTime.utc_now()
      )

      assert %{"data" => %{"activity" => %{"participants" => participants}}} =
               query_gql(variables: %{slug: "pottery"})

      names = participants |> Enum.map(& &1["name"]) |> Enum.sort()
      assert names == ["Alice", "Bob"]
    end

    test "viewerIsRegistered is false once the viewer has left (soft-deleted attendance)" do
      activity = insert(:activity, slug: "left")
      viewer = insert(:user)

      insert(:activity_attendance,
        activity: activity,
        user: viewer,
        deleted_at: DateTime.utc_now()
      )

      assert %{"data" => %{"activity" => %{"viewerIsRegistered" => false}}} =
               query_gql(current_user: viewer, variables: %{slug: "left"})
    end

    test "returns null for an unknown slug" do
      assert %{"data" => %{"activity" => nil}} = query_gql(variables: %{slug: "does-not-exist"})
    end

    test "returns null for archived or draft activities" do
      insert(:activity, slug: "archived-one", archived_at: DateTime.utc_now())
      insert(:activity, slug: "draft-one", published_at: nil)

      assert %{"data" => %{"activity" => nil}} = query_gql(variables: %{slug: "archived-one"})
      assert %{"data" => %{"activity" => nil}} = query_gql(variables: %{slug: "draft-one"})
    end
  end
end
