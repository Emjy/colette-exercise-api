defmodule Exercise.Communities.ActivitiesTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory

  alias Exercise.Communities.Activities

  describe "list_visible/0" do
    test "returns only published, non-archived activities" do
      visible = insert(:activity)
      _archived = insert(:activity, archived_at: DateTime.utc_now())
      _draft = insert(:activity, published_at: nil)

      assert [found] = Activities.list_visible()
      assert found.id == visible.id
    end

    test "orders activities by start time, soonest first" do
      now = DateTime.utc_now()
      later = insert(:activity, starts_at: DateTime.add(now, 10, :day))
      sooner = insert(:activity, starts_at: DateTime.add(now, 2, :day))
      middle = insert(:activity, starts_at: DateTime.add(now, 5, :day))

      ids = Enum.map(Activities.list_visible(), & &1.id)
      assert ids == [sooner.id, middle.id, later.id]
    end
  end

  describe "get_visible/1" do
    test "returns a visible activity by id" do
      activity = insert(:activity)
      assert %{id: id} = Activities.get_visible(activity.id)
      assert id == activity.id
    end

    test "returns nil for an archived or unknown activity" do
      archived = insert(:activity, archived_at: DateTime.utc_now())
      assert Activities.get_visible(archived.id) == nil
      assert Activities.get_visible(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_visible_by_slug/1" do
    test "returns a visible activity by slug" do
      insert(:activity, slug: "open-pottery")
      assert %{slug: "open-pottery"} = Activities.get_visible_by_slug("open-pottery")
    end

    test "returns nil for a draft or unknown slug" do
      insert(:activity, slug: "draft", published_at: nil)
      assert Activities.get_visible_by_slug("draft") == nil
      assert Activities.get_visible_by_slug("nope") == nil
    end
  end
end
