defmodule Exercise.Errors.UnhandledError do
  @moduledoc """
  Error to be returned when an unhandled exception is encountered
  """

  use Exercise.ExErrors

  defexerror([:error, message: "An unhandled error occurred"], required_fields: [:error])
end
