# frozen_string_literal: true

class AddUniqueIndexToEvents < ActiveRecord::Migration[8.1]
  def up
    # Remove existing duplicates before adding the unique constraint.
    # Keeps the row with the lowest id for each (uid, dtstart, dtend, calendar_id) group.
    execute <<~SQL.squish
      WITH duplicates AS (
        SELECT id, ROW_NUMBER() OVER (
          PARTITION BY uid, dtstart, dtend, calendar_id
          ORDER BY id
        ) as rn
        FROM events
      )
      DELETE FROM events WHERE id IN (
        SELECT id FROM duplicates WHERE rn > 1
      )
    SQL

    add_index :events, %i[calendar_id uid dtstart dtend],
              unique: true,
              name: 'index_events_unique_per_calendar'
  end

  def down
    remove_index :events, name: 'index_events_unique_per_calendar'
  end
end
