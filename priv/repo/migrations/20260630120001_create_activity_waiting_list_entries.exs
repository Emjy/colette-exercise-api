defmodule Exercise.Repo.Migrations.CreateActivityWaitingListEntries do
  use Ecto.Migration

  def change do
    create table(:activity_waiting_list_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :activity_id, references(:activities, type: :binary_id, on_delete: :delete_all),
        null: false

      add :converted_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    # Partial unique index: one *active* waiting list entry per (user, activity).
    # Converted entries (converted_at set) don't count, allowing a member to
    # re-join if they register, leave, and the activity fills up again.
    create unique_index(:activity_waiting_list_entries, [:user_id, :activity_id],
             where: "converted_at IS NULL"
           )
  end
end
