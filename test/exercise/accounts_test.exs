defmodule Exercise.AccountsTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory

  alias Exercise.Accounts
  alias Exercise.Errors.NotFoundError

  test "get_user/1 returns a non-archived user" do
    user = insert(:user)
    assert {:ok, found} = Accounts.get_user(user.id)
    assert found.id == user.id
  end

  test "get_user/1 returns a NotFoundError for an archived user" do
    user = insert(:user, archived_at: DateTime.utc_now())

    assert {:error, %NotFoundError{type: "User", fields: %{id: id}}} =
             Accounts.get_user(user.id)

    assert id == user.id
  end
end
