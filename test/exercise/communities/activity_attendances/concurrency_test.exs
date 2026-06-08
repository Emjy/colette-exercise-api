defmodule Exercise.Communities.ActivityAttendances.ConcurrencyTest do
  @moduledoc """
  Real DB concurrency: each task registers on its own committed connection via
  `Sandbox.unboxed_run/2`, so the capacity check faces genuine parallel writes.
  Uses `ExUnit.Case` (not DataCase) — there is no per-test sandbox transaction, so
  data is committed; `on_exit` cleans it up. The activity is a draft, so it stays
  invisible to other tests' visibility queries.
  """
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Exercise.Accounts.User
  alias Exercise.Communities.Activity
  alias Exercise.Communities.ActivityAttendance
  alias Exercise.Communities.ActivityAttendances
  alias Exercise.Repo

  @max 3
  @concurrent 25

  setup do
    on_exit(fn ->
      Sandbox.unboxed_run(Repo, fn ->
        Repo.delete_all(ActivityAttendance)
        Repo.delete_all(Activity)
        Repo.delete_all(User)
      end)
    end)

    :ok
  end

  test "concurrent registrations never exceed max_attendees" do
    {activity, users} = seed_activity_and_users()

    results =
      users
      |> Task.async_stream(
        fn user ->
          Sandbox.unboxed_run(Repo, fn ->
            ActivityAttendances.register_to_activity(user, activity)
          end)
        end,
        max_concurrency: @concurrent,
        timeout: 30_000,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    successes = Enum.count(results, &match?({:ok, _}, &1))
    full_errors = Enum.count(results, &match?({:error, %Ecto.Changeset{}}, &1))
    final_count = Sandbox.unboxed_run(Repo, fn -> Repo.aggregate(ActivityAttendance, :count) end)

    assert successes == @max,
           "expected exactly #{@max} successful registrations, got #{successes} (overbooked)"

    assert final_count == @max, "expected #{@max} attendances persisted, got #{final_count}"
    assert full_errors == @concurrent - @max
  end

  defp seed_activity_and_users do
    Sandbox.unboxed_run(Repo, fn ->
      creator = Repo.insert!(%User{email: uniq_email("creator"), name: "Creator"})

      activity =
        Repo.insert!(%Activity{
          title: "Race",
          slug: "race-#{System.unique_integer([:positive])}",
          starts_at: DateTime.utc_now(),
          max_attendees: @max,
          creator_id: creator.id,
          published_at: nil
        })

      users =
        for _ <- 1..@concurrent, do: Repo.insert!(%User{email: uniq_email("u"), name: "U"})

      {activity, users}
    end)
  end

  defp uniq_email(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}@example.com"
end
