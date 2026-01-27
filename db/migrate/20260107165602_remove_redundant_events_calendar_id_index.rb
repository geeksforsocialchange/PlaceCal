# frozen_string_literal: true

class RemoveRedundantEventsCalendarIdIndex < ActiveRecord::Migration[7.2]
  def change
    # The composite index (calendar_id, dtstart) covers queries on calendar_id alone,
    # making this single-column index redundant
    remove_index :events, :calendar_id, name: :index_events_on_calendar_id
  end
end
