# frozen_string_literal: true

class AddEventsCalendarIdDtstartIndex < ActiveRecord::Migration[7.2]
  def change
    # Composite index for common query pattern: events for a calendar in date range
    add_index :events, %i[calendar_id dtstart], name: 'index_events_calendar_id_dtstart'
  end
end
