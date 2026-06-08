defmodule ExerciseWeb.Schema.Mutations.UnregisterFromActivityTest do
  @moduledoc false
  use ExerciseWeb.ConnCase, async: true
  use ExerciseWeb.GqlCase

  import Exercise.Factory

  @moduletag :gql

  load_gql_file("UnregisterFromActivity.gql")

  describe "UnregisterFromActivity.gql" do
    test "an authenticated member can unregister" do
      user = insert(:user)
      activity = insert(:activity)
      insert(:activity_attendance, user: user, activity: activity)

      data = query_gql(current_user: user, variables: %{id: activity.id})
      assert data["data"]["unregisterFromActivity"]["attendance"]["id"]
    end

    test "unregistering when not registered returns a DeregisterFromActivityError" do
      activity = insert(:activity)

      data = query_gql(current_user: insert(:user), variables: %{id: activity.id})

      assert [%{"extensions" => %{"errorCode" => "DeregisterFromActivityError"}}] =
               data["errors"]
    end
  end
end
