defmodule Exercise.Accounts do
  @moduledoc """
  The Accounts context.

  It delegates to sub-contexts for clarity.
  """
  alias Exercise.Accounts.Users

  ## Users

  defdelegate get_user(id), to: Users
end
