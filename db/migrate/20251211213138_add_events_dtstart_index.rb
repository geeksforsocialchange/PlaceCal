# frozen_string_literal: true

class AddEventsDtstartIndex < ActiveRecord::Migration[7.2]
  def change
    # Index for date range queries (find_by_day, find_by_week, future, upcoming, past, ical_feed)
    add_index :events, :dtstart, name: 'index_events_dtstart'
  end
end
