# frozen_string_literal: true

class AddFailureNotifiedAtToCalendars < ActiveRecord::Migration[8.1]
  def up
    add_column :calendars, :failure_notified_at, :datetime

    # Calendars already failing count as notified, so deploying emails nobody; one UPDATE on a small table
    safety_assured do
      execute "UPDATE calendars SET failure_notified_at = NOW() WHERE calendar_state IN ('error', 'bad_source')"
    end
  end

  def down
    remove_column :calendars, :failure_notified_at
  end
end
