defmodule Exercise.ExErrors.ExError do
  @moduledoc """
  Defines an ExError
  """

  @type t :: %{
          required(:__struct__) => module,
          required(:__ex_error__) => true,
          optional(atom) => any
        }

  @callback new(term) :: t
end
