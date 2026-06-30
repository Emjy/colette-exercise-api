defmodule Exercise.Communities do
  @moduledoc """
  The Communities context.

  It delegates to sub-contexts for clarity.
  """
  alias Exercise.Communities.Activities
  alias Exercise.Communities.ActivityAttendances
  alias Exercise.Communities.ActivityWaitingLists

  ## Activities

  defdelegate list_visible(), to: Activities
  defdelegate get_visible(id), to: Activities
  defdelegate get_visible_by_slug(slug), to: Activities

  ## ActivityAttendances

  defdelegate attendance_count(activity), to: ActivityAttendances
  defdelegate register_to_activity(user, activity), to: ActivityAttendances
  defdelegate unregister_from_activity(user, activity), to: ActivityAttendances

  ## ActivityWaitingLists

  defdelegate join_waiting_list(user, activity), to: ActivityWaitingLists
end
