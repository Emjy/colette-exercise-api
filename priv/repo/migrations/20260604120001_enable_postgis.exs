defmodule Exercise.Repo.Migrations.EnablePostgis do
  use Ecto.Migration

  def up, do: execute("CREATE EXTENSION IF NOT EXISTS postgis")
  def down, do: execute("DROP EXTENSION IF EXISTS postgis")
end
