defmodule ExerciseWeb.GqlCase do
  @moduledoc """
  GqlCase for the exercise's GraphQL API, powered by the `gql_case` package.

  The bearer token *is* the user id for this exercise (no JWT). Use it alongside
  `ExerciseWeb.ConnCase`:

      use ExerciseWeb.ConnCase, async: true
      use ExerciseWeb.GqlCase

      import Exercise.Factory

      load_gql_file("Activities.gql")

      test "lists activities" do
        query_gql(current_user: insert(:user), variables: %{})
      end
  """

  @doc "Bearer-token resolver: this exercise's token is simply the user id."
  def bearer(%{id: id}), do: {:ok, id, %{}}

  use GqlCase,
    gql_path: "/api",
    jwt_bearer_fn: &__MODULE__.bearer/1,
    default_headers: [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
end
