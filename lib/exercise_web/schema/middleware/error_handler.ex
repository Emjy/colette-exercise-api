defmodule ExerciseWeb.Schema.Middleware.ErrorHandler do
  @moduledoc """
  Middleware that normalises resolver errors into GraphQL errors.

  Every error becomes an `Exercise.Errors` (ex_error) struct — changesets are
  expanded into `ValidationError`s, anything unrecognised becomes an
  `UnhandledError` — and is then rendered with its `error_code` (and any extra
  fields) under `extensions`. The app never returns a bare atom error.
  """

  @behaviour Absinthe.Middleware

  require Logger

  use Exercise.ExErrors

  alias Ecto.Changeset
  alias Exercise.Errors

  @impl true
  def call(resolution, _config) do
    errors =
      resolution.errors
      |> Enum.map(&normalize/1)
      |> List.flatten()
      |> Enum.map(&to_absinthe_format/1)

    %{resolution | errors: errors}
  end

  defp normalize({:error, error}) when is_ex_error(error), do: handle(error)

  defp normalize({:error, _operation, %Changeset{} = changeset, _changes}),
    do: handle(changeset)

  defp normalize({:error, %Changeset{} = changeset}),
    do: handle(changeset)

  defp normalize(other), do: handle(other)

  defp handle(error) when is_ex_error(error), do: error

  defp handle(errors) when is_list(errors), do: Enum.map(errors, &handle/1)

  defp handle(%Changeset{} = changeset) do
    changeset
    |> traverse_changeset()
    |> build_validation_error()
  end

  defp handle(other) do
    Logger.error("Unhandled error term:\n#{inspect(other)}")
    Errors.UnhandledError.new(error: inspect(other))
  end

  defp traverse_changeset(%Changeset{} = changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp build_validation_error(%{} = traversed_changeset) do
    Enum.map(traversed_changeset, fn
      {k, v} when is_list(v) ->
        Errors.ValidationError.new(reasons: v, field: k)

      {_k, %{} = map} ->
        build_validation_error(map)
    end)
  end

  defp to_absinthe_format(error) when is_ex_error(error) do
    error = Map.from_struct(error)

    extensions_content =
      error
      |> Map.drop([:message, :path, :__ex_error__])
      |> Map.new(fn {key, value} ->
        formatted_key =
          key
          |> Atom.to_string()
          |> Macro.camelize()
          |> downcase_first_character()

        {formatted_key, value}
      end)

    Map.put(error, :extensions, extensions_content)
  end

  defp to_absinthe_format(error), do: error

  defp downcase_first_character(string) when is_binary(string) do
    with <<c::utf8, rest::binary>> <- string,
         do: String.downcase(<<c>>) <> rest
  end
end
