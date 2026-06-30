defmodule Exercise.Communities.ActivityWaitingListsTest do
  use Exercise.DataCase, async: true
  use ExEventBus.Testing, ex_event_bus: Exercise.EventBus
  use Oban.Testing, repo: Exercise.Repo

  import Exercise.Factory

  alias Exercise.Communities.ActivityAttendances
  alias Exercise.Communities.ActivityWaitingListEntries.Query
  alias Exercise.Communities.ActivityWaitingListEntry
  alias Exercise.Communities.ActivityWaitingLists
  alias Exercise.Communities.ActivityWaitingLists.NotificationWorker
  alias Exercise.Repo

  describe "join_waiting_list/2" do
    test "adds a member to the waiting list of a full activity" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      assert {:ok, entry} = ActivityWaitingLists.join_waiting_list(user, activity)
      assert entry.user_id == user.id
      assert entry.activity_id == activity.id
      assert is_nil(entry.converted_at)
    end

    test "rejects joining when the activity is not full" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 10)

      assert {:error, changeset} = ActivityWaitingLists.join_waiting_list(user, activity)
      assert %{base: ["activity is not full"]} = errors_on(changeset)
    end

    test "rejects joining when the member is already registered" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, user: user, activity: activity)

      assert {:error, changeset} = ActivityWaitingLists.join_waiting_list(user, activity)
      assert %{base: ["already registered to this activity"]} = errors_on(changeset)
    end

    test "rejects a duplicate active waiting list entry" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      assert {:ok, _} = ActivityWaitingLists.join_waiting_list(user, activity)
      assert {:error, changeset} = ActivityWaitingLists.join_waiting_list(user, activity)
      assert %{user_id: ["has already been taken"]} = errors_on(changeset)
    end

    test "publishes WaitingListEntryCreated on success" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      assert {:ok, _} = ActivityWaitingLists.join_waiting_list(user, activity)
      assert_event_received(Exercise.Communities.Events.WaitingListEntryCreated)
    end

    test "a member can rejoin after their previous entry was converted" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)

      {:ok, entry} = ActivityWaitingLists.join_waiting_list(user, activity)
      Repo.update!(ActivityWaitingListEntry.convert_changeset(entry))

      assert {:ok, _} = ActivityWaitingLists.join_waiting_list(user, activity)
    end
  end

  describe "convert_entry/2" do
    test "stamps converted_at on the active waiting list entry" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)
      {:ok, _} = ActivityWaitingLists.join_waiting_list(user, activity)

      assert {:ok, converted} = ActivityWaitingLists.convert_entry(user, activity)
      assert converted.converted_at
    end

    test "returns {:ok, nil} when no active entry exists" do
      user = insert(:user)
      activity = insert(:activity)

      assert {:ok, nil} = ActivityWaitingLists.convert_entry(user, activity)
    end

    test "does not convert an already-converted entry" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      insert(:activity_attendance, activity: activity)
      {:ok, entry} = ActivityWaitingLists.join_waiting_list(user, activity)
      Repo.update!(ActivityWaitingListEntry.convert_changeset(entry))

      assert {:ok, nil} = ActivityWaitingLists.convert_entry(user, activity)
    end
  end

  describe "register_to_activity converts waiting list entry" do
    test "converting the entry when registering from the waiting list" do
      user = insert(:user)
      activity = insert(:activity, max_attendees: 1)
      other = insert(:user)
      insert(:activity_attendance, user: other, activity: activity)

      {:ok, _} = ActivityWaitingLists.join_waiting_list(user, activity)

      ActivityAttendances.unregister_from_activity(other, activity)

      assert {:ok, _} = ActivityAttendances.register_to_activity(user, activity)

      entry =
        Query.base()
        |> Query.with_user_id(user.id)
        |> Query.with_activity_id(activity.id)
        |> Repo.one()

      assert entry.converted_at
    end
  end

  describe "NotificationHandler" do
    test "enqueues a notification job for each waiting list member when a seat frees" do
      activity = insert(:activity, max_attendees: 1)
      member1 = insert(:user)
      member2 = insert(:user)
      registered = insert(:user)

      insert(:activity_attendance, user: registered, activity: activity)
      {:ok, _} = ActivityWaitingLists.join_waiting_list(member1, activity)
      {:ok, _} = ActivityWaitingLists.join_waiting_list(member2, activity)

      ActivityAttendances.unregister_from_activity(registered, activity)

      execute_events()

      assert_enqueued(
        worker: NotificationWorker,
        args: %{user_id: member1.id, activity_id: activity.id}
      )

      assert_enqueued(
        worker: NotificationWorker,
        args: %{user_id: member2.id, activity_id: activity.id}
      )
    end

    test "does not enqueue jobs when the waiting list is empty" do
      activity = insert(:activity, max_attendees: 1)
      registered = insert(:user)
      insert(:activity_attendance, user: registered, activity: activity)

      ActivityAttendances.unregister_from_activity(registered, activity)

      execute_events()

      refute_enqueued(worker: NotificationWorker)
    end

    test "does not notify members whose entry was already converted" do
      activity = insert(:activity, max_attendees: 1)
      member = insert(:user)
      registered = insert(:user)

      insert(:activity_attendance, user: registered, activity: activity)
      {:ok, entry} = ActivityWaitingLists.join_waiting_list(member, activity)
      Repo.update!(ActivityWaitingListEntry.convert_changeset(entry))

      ActivityAttendances.unregister_from_activity(registered, activity)

      execute_events()

      refute_enqueued(worker: NotificationWorker, args: %{user_id: member.id})
    end
  end
end
