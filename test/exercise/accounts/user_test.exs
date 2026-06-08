defmodule Exercise.Accounts.UserTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory

  alias Exercise.Accounts.User
  alias Exercise.Repo

  describe "changeset/2" do
    test "is valid with email and name" do
      assert %Ecto.Changeset{valid?: true} =
               User.changeset(%User{}, %{email: "a@example.com", name: "Alice"})
    end

    test "requires email and name" do
      errors = errors_on(User.changeset(%User{}, %{}))
      assert errors.email == ["can't be blank"]
      assert errors.name == ["can't be blank"]
    end

    test "enforces a unique email" do
      insert(:user, email: "taken@example.com")

      {:error, changeset} =
        %User{} |> User.changeset(%{email: "taken@example.com", name: "X"}) |> Repo.insert()

      assert errors_on(changeset).email == ["has already been taken"]
    end
  end
end
