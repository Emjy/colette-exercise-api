defmodule Exercise.Errors.ValidationError do
  @moduledoc """
  Error to be returned when validations fail (mainly from changesets)
  """

  use Exercise.ExErrors

  defexerror([:reasons, :field, message: "A validation failed"],
    required_fields: [:reasons, :field]
  )
end
