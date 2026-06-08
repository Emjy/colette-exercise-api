defmodule Exercise.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :starts_at, :utc_datetime_usec, null: false
      add :max_attendees, :integer, null: false
      add :price_amount, :integer, null: false, default: 0
      add :price_currency, :string, null: false, default: "EUR"
      add :postal_code, :string
      add :creator_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :published_at, :utc_datetime_usec
      add :archived_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:activities, [:slug])

    execute(
      "ALTER TABLE activities ADD COLUMN location geometry(Point, 4326)",
      "ALTER TABLE activities DROP COLUMN location"
    )

    create index(:activities, [:location], using: "GIST")
  end
end
