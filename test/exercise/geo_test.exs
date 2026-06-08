defmodule Exercise.GeoTest do
  use Exercise.DataCase, async: true

  import Exercise.Factory
  import Ecto.Query

  alias Exercise.Communities.Activities.Query
  alias Exercise.Repo

  describe "point/2" do
    test "builds a WGS84 point from longitude/latitude" do
      assert %Geo.Point{coordinates: {4.35, 50.85}, srid: 4326} = Exercise.Geo.point(4.35, 50.85)
    end
  end

  describe "order_by_distance/2" do
    test "orders activities nearest-first and excludes those without a location" do
      near = insert(:activity, location: Exercise.Geo.point(4.35, 50.85))
      far = insert(:activity, location: Exercise.Geo.point(5.5, 52.0))
      _no_location = insert(:activity, location: nil)

      ids =
        Query.base()
        |> Exercise.Geo.order_by_distance(Exercise.Geo.point(4.35, 50.85))
        |> select([a], a.id)
        |> Repo.all()

      assert ids == [near.id, far.id]
    end
  end
end
