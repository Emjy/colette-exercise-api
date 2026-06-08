defmodule Exercise.Communities.ActivityTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory

  alias Exercise.Communities.Activity
  alias Exercise.Repo

  @valid %{title: "Yoga", slug: "yoga", starts_at: DateTime.utc_now(), max_attendees: 10}

  describe "changeset/2" do
    test "is valid with the required attrs" do
      assert %Ecto.Changeset{valid?: true} = Activity.changeset(%Activity{}, @valid)
    end

    test "requires title, slug, starts_at and max_attendees" do
      errors = errors_on(Activity.changeset(%Activity{}, %{}))
      assert errors.title == ["can't be blank"]
      assert errors.slug == ["can't be blank"]
      assert errors.starts_at == ["can't be blank"]
      assert errors.max_attendees == ["can't be blank"]
    end

    test "rejects a non-positive max_attendees" do
      changeset = Activity.changeset(%Activity{}, %{@valid | max_attendees: 0})
      assert errors_on(changeset).max_attendees == ["must be greater than 0"]
    end

    test "enforces a unique slug" do
      insert(:activity, slug: "taken")

      {:error, changeset} =
        %Activity{} |> Activity.changeset(%{@valid | slug: "taken"}) |> Repo.insert()

      assert errors_on(changeset).slug == ["has already been taken"]
    end
  end
end
