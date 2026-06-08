defmodule Exercise.ExErrors do
  @moduledoc """
  Defines macros to use ExErrors.
  """

  alias __MODULE__.ExError

  # credo:disable-for-next-line
  defmacro defexerror(fields, opts \\ []) do
    quote bind_quoted: [fields: fields, opts: opts] do
      Elixir.Kernel.@(behaviour(ExError))

      @ex_error_opts opts

      defstruct(
        [
          __ex_error__: true,
          error_code: __MODULE__ |> to_string() |> String.split(".") |> List.last()
        ] ++ fields
      )

      # Calls to Kernel functions must be fully-qualified to ensure
      # reproducible builds; otherwise, this macro will generate ASTs
      # with different metadata (:import, :context) depending on if
      # it is the bootstrapped version or not.
      Elixir.Kernel.@(impl(true))

      def new(args \\ []) when Kernel.is_list(args) do
        struct = __struct__()
        {valid, invalid} = Enum.split_with(args, fn {k, _} -> Map.has_key?(struct, k) end)

        verify_invalid_provided_keys(invalid)
        verify_valid_provided_keys(valid)

        Kernel.struct!(struct, valid)
      end

      defp verify_invalid_provided_keys(provided_keys) do
        case provided_keys do
          [] ->
            :ok

          _ ->
            IO.warn(
              "the following fields are unknown when defining " <>
                "#{Kernel.inspect(__MODULE__)}: #{Kernel.inspect(provided_keys)}. " <>
                "Please make sure to only give known fields."
            )
        end
      end

      defp verify_valid_provided_keys(provided_keys) do
        required_keys = Keyword.get(@ex_error_opts, :required_fields, [])

        provided_required_keys =
          provided_keys
          |> Map.new()
          |> Map.take(required_keys)
          |> Map.keys()

        case required_keys -- provided_required_keys do
          [] ->
            :ok

          missing_keys ->
            raise ArgumentError,
                  "the following fields must also be given when building " <>
                    "struct #{inspect(__MODULE__)}: #{inspect(missing_keys)}"
        end
      end

      defoverridable new: 1

      def error_code, do: Map.get(__struct__(), :error_code)

      def spec,
        do: %{error_code: error_code(), fields: all_fields(), required_fields: required_fields()}

      defp all_fields,
        do: (__struct__() |> Map.keys()) -- [:__struct__, :__ex_error__]

      defp required_fields,
        do: Keyword.get(@ex_error_opts, :required_fields, [])
    end
  end

  @doc """
  Returns true if `term` is an ex_error; otherwise returns `false`.
  Allowed in guard tests.
  ## Examples
      iex> is_ex_error(%MyExError{})
      true
      iex> is_ex_error(%{})
      false
  """
  defmacro is_ex_error(term) do
    case __CALLER__.context do
      nil ->
        ex_error_without_context?(term)

      :match ->
        invalid_match!(:is_ex_error)

      :guard ->
        ex_error_guard?(term)
    end
  end

  @doc """
  Returns true if `term` is an ex_error of `name`; otherwise returns `false`.
  Allowed in guard tests.
  ## Examples
      iex> is_ex_error(%MyExError{}, MyExError)
      true
      iex> is_ex_error(%MyExError{}, Macro.Env)
      false
  """
  defmacro is_ex_error(term, name) do
    case __CALLER__.context do
      nil ->
        ex_error_without_context?(term, name)

      :match ->
        invalid_match!(:is_ex_error)

      :guard ->
        ex_error_guard?(term, name)
    end
  end

  defp ex_error_without_context?(term) do
    quote do
      case unquote(term) do
        %_{__ex_error__: true} -> true
        _ -> false
      end
    end
  end

  defp ex_error_without_context?(term, name) do
    quote do
      case unquote(name) do
        name when is_atom(name) ->
          case unquote(term) do
            %{__struct__: ^name, __ex_error__: true} -> true
            _ -> false
          end

        _ ->
          raise ArgumentError
      end
    end
  end

  defp ex_error_guard?(term) do
    quote do
      is_map(unquote(term)) and :erlang.is_map_key(:__struct__, unquote(term)) and
        is_atom(:erlang.map_get(:__struct__, unquote(term))) and
        :erlang.is_map_key(:__ex_error__, unquote(term)) and
        :erlang.map_get(:__ex_error__, unquote(term)) == true
    end
  end

  defp ex_error_guard?(term, name) do
    quote do
      is_map(unquote(term)) and
        (is_atom(unquote(name)) or :fail) and
        :erlang.is_map_key(:__struct__, unquote(term)) and
        :erlang.map_get(:__struct__, unquote(term)) == unquote(name) and
        :erlang.is_map_key(:__ex_error__, unquote(term)) and
        :erlang.map_get(:__ex_error__, unquote(term)) == true
    end
  end

  defp invalid_match!(exp) do
    raise ArgumentError,
          "invalid expression in match, #{exp} is not allowed in patterns " <>
            "such as function clauses, case clauses or on the left side of the = operator"
  end

  defmacro __using__(_opts) do
    quote do
      import Exercise.ExErrors
    end
  end

  @doc """
  For a given `application`, lists all modules that define ExError
  """
  @spec list_errors(application :: atom()) :: [ExError.t()]
  def list_errors(application) when is_atom(application) do
    get_application_modules(application)
    |> Enum.filter(fn module ->
      defines_struct? =
        module.__info__(:functions)
        |> Enum.any?(fn {name, _arity} -> name == :__struct__ end)

      defines_struct? &&
        struct(module, [])
        |> Map.keys()
        |> Enum.any?(fn key -> key == :__ex_error__ end)
    end)
  end

  def list_errors(_application), do: []

  @doc """
  For a given `application`, lists all error specs defined in modules which `use ExErrors`
  """
  @spec list_error_specs(application :: atom()) :: [
          %{error_code: term(), fields: [atom()], required_fields: [atom()]}
        ]
  def list_error_specs(application) do
    list_errors(application)
    |> Enum.map(& &1.spec())
  end

  defp get_application_modules(application) do
    case :application.get_key(application, :modules) do
      {:ok, modules} when is_list(modules) -> modules
      _ -> []
    end
  end
end
