# frozen_string_literal: true

class AddEventsUidIndex < ActiveRecord::Migration[7.2]
  def change
    # Index for duplicate event checking during calendar imports
    add_index :events, :uid, name: 'index_events_uid'
  end
end
