defmodule Exercise.Repo.Migrations.AddAttendeeCountToActivities do
  use Ecto.Migration

  def up do
    alter table(:activities) do
      add :attendee_count, :integer, default: 0, null: false
    end

    # Keep activities.attendee_count in sync with the number of *active*
    # (non-soft-deleted) attendances — maintained entirely in the database.
    execute("""
    CREATE OR REPLACE FUNCTION count_activity_attendances()
    RETURNS TRIGGER AS $$
    BEGIN
      UPDATE activities
      SET attendee_count = (
        SELECT COUNT(id) FROM activity_attendances
        WHERE activity_attendances.deleted_at IS NULL
          AND activity_attendances.activity_id = COALESCE(NEW.activity_id, OLD.activity_id)
      )
      WHERE id = COALESCE(NEW.activity_id, OLD.activity_id);
      RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER attendee_count_after_insert
    AFTER INSERT ON activity_attendances FOR EACH ROW
    EXECUTE PROCEDURE count_activity_attendances();
    """)

    execute("""
    CREATE TRIGGER attendee_count_after_update
    AFTER UPDATE OF deleted_at ON activity_attendances FOR EACH ROW
    EXECUTE PROCEDURE count_activity_attendances();
    """)

    execute("""
    CREATE TRIGGER attendee_count_after_delete
    AFTER DELETE ON activity_attendances FOR EACH ROW
    EXECUTE PROCEDURE count_activity_attendances();
    """)

    # Backfill existing rows.
    execute("""
    UPDATE activities SET attendee_count = (
      SELECT COUNT(id) FROM activity_attendances
      WHERE activity_attendances.deleted_at IS NULL
        AND activity_attendances.activity_id = activities.id
    );
    """)
  end

  def down do
    execute("DROP TRIGGER IF EXISTS attendee_count_after_insert ON activity_attendances;")
    execute("DROP TRIGGER IF EXISTS attendee_count_after_update ON activity_attendances;")
    execute("DROP TRIGGER IF EXISTS attendee_count_after_delete ON activity_attendances;")
    execute("DROP FUNCTION IF EXISTS count_activity_attendances;")

    alter table(:activities) do
      remove :attendee_count
    end
  end
end
