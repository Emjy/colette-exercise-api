defmodule Exercise.Factory do
  @moduledoc "ExMachina factories for tests."
  use ExMachina.Ecto, repo: Exercise.Repo

  alias Exercise.Accounts.User
  alias Exercise.Communities.Activity
  alias Exercise.Communities.ActivityAttendance
  alias Exercise.Communities.ActivityWaitingListEntry

  def user_factory do
    %User{
      email: "user#{System.unique_integer([:positive])}@example.com",
      name: "Test User"
    }
  end

  def activity_factory do
    %Activity{
      title: sequence(:title, &"Activity #{&1}"),
      slug: sequence(:slug, &"activity-#{&1}"),
      description: "A lovely activity",
      starts_at: DateTime.add(DateTime.utc_now(), 7, :day),
      max_attendees: 10,
      price_amount: 0,
      price_currency: "EUR",
      postal_code: "1000",
      location: %Geo.Point{coordinates: {4.35, 50.85}, srid: 4326},
      published_at: DateTime.utc_now(),
      creator: build(:user)
    }
  end

  def activity_attendance_factory do
    %ActivityAttendance{user: build(:user), activity: build(:activity)}
  end

  def activity_waiting_list_entry_factory do
    %ActivityWaitingListEntry{user: build(:user), activity: build(:activity)}
  end
end
