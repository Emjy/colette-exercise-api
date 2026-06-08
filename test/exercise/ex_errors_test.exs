defmodule Exercise.ExErrorsTest do
  use ExUnit.Case, async: true

  use Exercise.ExErrors

  defmodule TestError do
    defexerror([:foo, :bar, message: "Foo"])
  end

  defmodule RequiredFieldsError do
    defexerror([:foo, :bar, message: "Foo"], required_fields: [:bar])
  end

  defp ex_error?(arg) when is_ex_error(arg), do: true
  defp ex_error?(_arg), do: false

  test "new/1 with enforce_keys and required_fields opts" do
    assert_raise ArgumentError, fn -> RequiredFieldsError.new([]) end
    assert_raise ArgumentError, fn -> RequiredFieldsError.new(foo: "Foo") end
    assert %RequiredFieldsError{} = RequiredFieldsError.new(bar: "Bar")
    assert %RequiredFieldsError{} = RequiredFieldsError.new(foo: "Foo", bar: "Bar")
  end

  test "list_errors/1" do
    assert errors = list_errors(:exercise)
    refute Enum.empty?(errors)
  end

  test "is_ex_error/1" do
    assert is_ex_error(%{}) == false
    assert is_ex_error([]) == false
    assert is_ex_error(%RuntimeError{}) == false
    assert is_ex_error(%{__ex_error__: "foo"}) == false
    assert is_ex_error(TestError.new([])) == true

    assert ex_error?(%{}) == false
    assert ex_error?([]) == false
    assert ex_error?(%RuntimeError{}) == false
    assert ex_error?(%{__ex_error__: "foo"}) == false
  end

  defp ex_error?(arg, name) when is_ex_error(arg, name), do: true
  defp ex_error?(_arg, _name), do: false

  test "is_ex_error/2" do
    assert is_ex_error(%RuntimeError{}, TestError) == false
    assert is_ex_error(TestError.new(message: "Bar"), TestError) == true
    assert is_ex_error(TestError.new(message: "Bar"), RuntimeError) == false

    assert ex_error?(TestError.new(message: "Bar"), TestError) == true
    assert ex_error?(TestError.new(message: "Bar"), RuntimeError) == false
  end
end
