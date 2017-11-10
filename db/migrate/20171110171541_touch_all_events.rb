class TouchAllEvents < ActiveRecord::Migration[5.1]
  def change
    # Fixes rrule sanitization
    Event.find_each(&:save)
  end
end
