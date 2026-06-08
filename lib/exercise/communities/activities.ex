defmodule Exercise.Communities.Activities do
  @moduledoc """
  The Activities context: activity reads (visibility-scoped). The web layer goes
  through `Exercise.Communities` — never `Repo` or a query module directly.
  """
  alias Exercise.Communities.Activities.Query
  alias Exercise.Repo

  ## Reads

  @doc "All activities visible to members (published, not archived), soonest first."
  def list_visible do
    Query.visible() |> Query.order_by_starts_at() |> Repo.all()
  end

  @doc "A single visible activity by id, or `nil`."
  def get_visible(id) do
    Query.visible() |> Repo.get(id)
  end

  @doc "A single visible activity by slug, or `nil`."
  def get_visible_by_slug(slug) do
    Query.base() |> Query.with_slug(slug) |> Query.visible() |> Repo.one()
  end
end
