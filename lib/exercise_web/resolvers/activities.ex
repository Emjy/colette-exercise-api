defmodule ExerciseWeb.Resolvers.Activities do
  @moduledoc "Resolvers for activity queries and mutations."
  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  alias Exercise.Communities
  alias Exercise.Communities.ActivityAttendances.Query, as: AttendanceQuery
  alias Exercise.Errors
  alias ExerciseWeb.Dataloaders.GenericEcto

  def list_activities(_parent, _args, _resolution) do
    {:ok, Communities.list_visible()}
  end

  @doc """
  Whether the current viewer has an active registration for the activity.

  Resolved through the dataloader: it loads the activity's active `:attendances`
  scoped to the current user, batching one query for the whole list (no N+1).
  Returns `false` when there is no signed-in viewer.
  """
  def viewer_is_registered(activity, _args, %{
        context: %{current_user: %{id: user_id}, loader: loader}
      }) do
    batch_key = {:attendances, %{query_fun: {&AttendanceQuery.with_user_id/2, user_id}}}

    loader
    |> Dataloader.load(GenericEcto, batch_key, activity)
    |> on_load(fn loaded ->
      {:ok, Dataloader.get(loaded, GenericEcto, batch_key, activity) != []}
    end)
  end

  def viewer_is_registered(_activity, _args, _resolution), do: {:ok, false}

  def get_activity(_parent, %{slug: slug}, _resolution) do
    {:ok, Communities.get_visible_by_slug(slug)}
  end

  def register(_parent, %{input: %{activity_id: id}}, %{context: %{current_user: user}}) do
    with {:ok, activity} <- fetch_visible(id),
         {:ok, attendance} <- Communities.register_to_activity(user, activity) do
      {:ok, %{attendance: attendance}}
    end
  end

  def unregister(_parent, %{input: %{activity_id: id}}, %{context: %{current_user: user}}) do
    with {:ok, activity} <- fetch_visible(id),
         {:ok, attendance} <- Communities.unregister_from_activity(user, activity) do
      {:ok, %{attendance: attendance}}
    end
  end

  defp fetch_visible(id) do
    case Communities.get_visible(id) do
      nil -> {:error, Errors.NotFoundError.new(type: "Activity", fields: %{id: id})}
      activity -> {:ok, activity}
    end
  end
end
