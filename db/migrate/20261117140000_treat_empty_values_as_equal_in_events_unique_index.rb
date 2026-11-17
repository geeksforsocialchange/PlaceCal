# frozen_string_literal: true

# Without NULLS NOT DISTINCT, two events with no end time (or uid or calendar) never count as duplicates
class TreatEmptyValuesAsEqualInEventsUniqueIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  COLUMNS = %i[calendar_id uid dtstart dtend].freeze
  NAME = 'index_events_unique_per_calendar'

  def up
    add_index :events, COLUMNS, unique: true, nulls_not_distinct: true, algorithm: :concurrently, name: "#{NAME}_new"
    remove_index :events, name: NAME, algorithm: :concurrently
    rename_index :events, "#{NAME}_new", NAME
  end

  def down
    add_index :events, COLUMNS, unique: true, algorithm: :concurrently, name: "#{NAME}_old"
    remove_index :events, name: NAME, algorithm: :concurrently
    rename_index :events, "#{NAME}_old", NAME
  end
end
