defmodule Exercise.Errors.UnauthenticatedError do
  @moduledoc """
  Error to be returned when the viewer is not authenticated and should be
  """

  use Exercise.ExErrors

  defexerror(message: "You must be authenticated")
end
