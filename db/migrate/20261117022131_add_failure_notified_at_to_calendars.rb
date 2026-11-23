# frozen_string_literal: true

class AddFailureNotifiedAtToCalendars < ActiveRecord::Migration[8.1]
  def up
    add_column :calendars, :failure_notified_at, :datetime

    # Calendars already failing count as notified, so deploying emails nobody; one UPDATE on a small table.
    # critical_error outlives the hourly requeue, so it also catches failing calendars caught mid-retry.
    safety_assured do
      execute <<~SQL.squish
        UPDATE calendars SET failure_notified_at = NOW()
        WHERE calendar_state IN ('error', 'bad_source') OR critical_error IS NOT NULL
      SQL
    end
  end

  def down
    remove_column :calendars, :failure_notified_at
  end
end
