defmodule Exercise.Errors.NotFoundError do
  @moduledoc """
  Error to be returned when an object is not found
  """

  use Exercise.ExErrors

  defexerror(
    [
      :fields,
      :type,
      message: "No records found with the given field values"
    ],
    required_fields: [:fields, :type]
  )
end
