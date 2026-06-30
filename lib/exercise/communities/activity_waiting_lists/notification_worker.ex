defmodule Exercise.Communities.ActivityWaitingLists.NotificationWorker do
  @moduledoc "Notifies a waiting list member that a spot has opened on an activity."
  use Oban.Worker, queue: :notifications

  alias Exercise.Accounts
  alias Exercise.Communities

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "activity_id" => activity_id}}) do
    with {:ok, user} <- Accounts.get_user(user_id),
         activity when not is_nil(activity) <- Communities.get_visible(activity_id) do
      IO.puts(
        "[NOTIFICATION] A spot has opened for \"#{activity.title}\" " <>
          "— http://localhost:5173/activities/#{activity.slug} (#{user.email})"
      )
    end

    :ok
  end
end
