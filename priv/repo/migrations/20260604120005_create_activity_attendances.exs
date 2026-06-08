defmodule Exercise.Repo.Migrations.CreateActivityAttendances do
  use Ecto.Migration

  def change do
    create table(:activity_attendances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :activity_id, references(:activities, type: :binary_id, on_delete: :delete_all),
        null: false

      add :deleted_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    # Partial unique index: one *active* attendance per (user, activity). Soft-deleted
    # rows (deleted_at set) don't count, so a member can re-register after leaving.
    create unique_index(:activity_attendances, [:user_id, :activity_id],
             where: "deleted_at IS NULL"
           )
  end
end
