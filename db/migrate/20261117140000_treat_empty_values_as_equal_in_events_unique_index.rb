# frozen_string_literal: true

# Without NULLS NOT DISTINCT, two events with no end time (or uid or calendar) never count as duplicates
class TreatEmptyValuesAsEqualInEventsUniqueIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  COLUMNS = %i[calendar_id uid dtstart dtend].freeze
  NAME = 'index_events_unique_per_calendar'

  def up
    destroy_duplicates

    add_index :events, COLUMNS, unique: true, nulls_not_distinct: true, algorithm: :concurrently, name: "#{NAME}_new"
    remove_index :events, name: NAME, algorithm: :concurrently
    rename_index :events, "#{NAME}_new", NAME
  end

  def down
    add_index :events, COLUMNS, unique: true, algorithm: :concurrently, name: "#{NAME}_old"
    remove_index :events, name: NAME, algorithm: :concurrently
    rename_index :events, "#{NAME}_old", NAME
  end

  # The index can't be built over duplicates. Destroy, not DELETE, so their image files and versions go too
  def destroy_duplicates
    Event.where(id: duplicate_ids).find_each(&:destroy)
  end

  private

  # Every row after the oldest in each group, with empty values counting as equal
  def duplicate_ids
    select_values(<<~SQL.squish)
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY #{COLUMNS.join(', ')} ORDER BY id) AS position FROM events
      ) ranked WHERE position > 1
    SQL
  end
end
