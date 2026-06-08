defmodule Exercise.Errors.DeregisterFromActivityError do
  @moduledoc """
  Error to be returned when a user can't deregister from an activity
  """

  use Exercise.ExErrors

  defexerror([:activity_id, message: "You can't deregister from the activity"],
    required_fields: [:activity_id]
  )
end
