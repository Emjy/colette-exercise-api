defmodule ExerciseWeb.Schema.Mutations.JoinWaitingListTest do
  @moduledoc false
  use ExerciseWeb.ConnCase, async: true
  use ExerciseWeb.GqlCase

  import Exercise.Factory

  @moduletag :gql

  load_gql_file("JoinWaitingList.gql")

  describe "JoinWaitingList.gql" do
    test "an authenticated member can join the waiting list of a full activity" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      data = query_gql(current_user: user, variables: %{id: activity.id})
      assert data["data"]["joinWaitingList"]["waitingListEntry"]["id"]
    end

    test "without auth returns an UnauthenticatedError" do
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      data = query_gql(variables: %{id: activity.id})
      assert [%{"extensions" => %{"errorCode" => "UnauthenticatedError"}}] = data["errors"]
    end

    test "joining a non-full activity returns a ValidationError" do
      activity = insert(:activity, max_attendees: 10)

      data = query_gql(current_user: insert(:user), variables: %{id: activity.id})

      assert [
               %{
                 "extensions" => %{
                   "errorCode" => "ValidationError",
                   "reasons" => ["activity is not full"]
                 }
               }
             ] = data["errors"]
    end

    test "joining twice returns a ValidationError" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)
      insert(:activity_waiting_list_entry, user: user, activity: activity)

      data = query_gql(current_user: user, variables: %{id: activity.id})
      assert [%{"extensions" => %{"errorCode" => "ValidationError"}}] = data["errors"]
    end

    test "joining a non-visible activity returns a NotFoundError" do
      archived = insert(:activity, archived_at: DateTime.utc_now(), max_attendees: 1)
      insert(:activity_attendance, activity: archived)

      data = query_gql(current_user: insert(:user), variables: %{id: archived.id})
      assert [%{"extensions" => %{"errorCode" => "NotFoundError"}}] = data["errors"]
    end
  end
end
