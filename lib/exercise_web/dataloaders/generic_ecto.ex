defmodule ExerciseWeb.Dataloaders.GenericEcto do
  @moduledoc false

  require Logger
  import Ecto.Query

  def data do
    Dataloader.Ecto.new(Exercise.Repo, query: &query/2, run_batch: &run_batch/5)
  end

  def query(queryable, params) do
    case params[:query_fun] do
      nil ->
        queryable

      query_fun when is_function(query_fun, 1) ->
        query_fun.(queryable)

      {query_fun, args} when is_function(query_fun, 2) ->
        query_fun.(queryable, args)

      not_implemented ->
        Logger.warning("Dataloader query function not implemented: #{inspect(not_implemented)}")

        queryable
    end
  end

  def run_batch(
        _queryable,
        query,
        {nil, :count},
        _inputs,
        repo_opts
      ) do
    Exercise.Repo.aggregate(query, :count, :id, repo_opts)
    |> List.wrap()
  end

  def run_batch(
        _queryable,
        query,
        {col, :count},
        inputs,
        repo_opts
      ) do
    default_count = 0

    result =
      query
      |> where([q], field(q, ^col) in ^inputs)
      |> group_by([q], field(q, ^col))
      |> select([q], {field(q, ^col), count("*")})
      |> Exercise.Repo.all(repo_opts)
      |> Map.new()

    for input <- inputs do
      Map.get(result, input, default_count)
    end
  end

  # Fallback to original run_batch
  def run_batch(queryable, query, col, inputs, repo_opts),
    do: Dataloader.Ecto.run_batch(Exercise.Repo, queryable, query, col, inputs, repo_opts)
end
