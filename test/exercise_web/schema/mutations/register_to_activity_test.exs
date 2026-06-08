defmodule ExerciseWeb.Schema.Mutations.RegisterToActivityTest do
  @moduledoc false
  use ExerciseWeb.ConnCase, async: true
  use ExerciseWeb.GqlCase

  import Exercise.Factory

  @moduletag :gql

  load_gql_file("RegisterToActivity.gql")

  describe "RegisterToActivity.gql" do
    test "an authenticated member can register" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 5)

      data = query_gql(current_user: user, variables: %{id: activity.id})
      assert data["data"]["registerToActivity"]["attendance"]["id"]
    end

    test "without auth returns an UnauthenticatedError" do
      activity = insert(:activity)

      data = query_gql(variables: %{id: activity.id})
      assert [%{"extensions" => %{"errorCode" => "UnauthenticatedError"}}] = data["errors"]
    end

    test "registering a full activity returns a ValidationError" do
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      data = query_gql(current_user: insert(:user), variables: %{id: activity.id})

      assert [
               %{
                 "extensions" => %{
                   "errorCode" => "ValidationError",
                   "reasons" => ["activity is full"]
                 }
               }
             ] = data["errors"]
    end

    test "registering a non-visible activity returns a NotFoundError" do
      archived = insert(:activity, archived_at: DateTime.utc_now())

      data = query_gql(current_user: insert(:user), variables: %{id: archived.id})
      assert [%{"extensions" => %{"errorCode" => "NotFoundError"}}] = data["errors"]
    end

    test "registering twice returns a ValidationError" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 5)
      insert(:activity_attendance, user: user, activity: activity)

      data = query_gql(current_user: user, variables: %{id: activity.id})
      assert [%{"extensions" => %{"errorCode" => "ValidationError"}}] = data["errors"]
    end
  end
end
