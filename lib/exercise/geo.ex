defmodule Exercise.Geo do
  @moduledoc "Geospatial helpers. Prefer these over hand-rolled distance math."
  import Ecto.Query

  @doc "Orders an activities query by distance from a point, nearest first."
  def order_by_distance(query, %Geo.Point{} = point) do
    from a in query,
      where: not is_nil(a.location),
      order_by: fragment("ST_Distance(?, ?)", a.location, ^point)
  end

  @doc "Builds a WGS84 point from longitude/latitude."
  def point(lng, lat), do: %Geo.Point{coordinates: {lng, lat}, srid: 4326}
end
