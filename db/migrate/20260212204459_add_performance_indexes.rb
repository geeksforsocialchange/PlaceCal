# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :calendars, :calendar_state, algorithm: :concurrently, if_not_exists: true
    add_index :events, %i[partner_id dtstart], algorithm: :concurrently, if_not_exists: true

    # The composite index above covers partner_id queries, making these redundant
    remove_index :events, name: :index_events_partner_id, algorithm: :concurrently, if_exists: true
    remove_index :events, name: :index_events_on_partner_id, algorithm: :concurrently, if_exists: true
  end

  def down
    add_index :events, :partner_id, name: :index_events_partner_id, algorithm: :concurrently, if_not_exists: true
    remove_index :events, %i[partner_id dtstart], algorithm: :concurrently, if_exists: true
    remove_index :calendars, :calendar_state, algorithm: :concurrently, if_exists: true
  end
end
