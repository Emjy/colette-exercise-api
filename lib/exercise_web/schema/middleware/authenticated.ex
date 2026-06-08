defmodule ExerciseWeb.Schema.Middleware.Authenticated do
  @moduledoc "Rejects the resolution unless there is a current_user in context."
  @behaviour Absinthe.Middleware

  alias Exercise.Errors

  def call(%{context: %{current_user: %_{}}} = resolution, _config), do: resolution

  def call(resolution, _config) do
    Absinthe.Resolution.put_result(
      resolution,
      {:error, Errors.UnauthenticatedError.new()}
    )
  end
end
