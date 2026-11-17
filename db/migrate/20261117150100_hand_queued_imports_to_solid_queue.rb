# frozen_string_literal: true

# Imports queued under delayed_job never run under Solid Queue; idle calendars are queued again by the next hourly scan
class HandQueuedImportsToSolidQueue < ActiveRecord::Migration[8.1]
  def up
    # A data change on a few hundred rows, with no locks beyond them
    safety_assured do
      execute <<~SQL.squish
        UPDATE calendars
        SET calendar_state = CASE WHEN calendar_state IN ('in_queue', 'in_worker') THEN 'idle' ELSE calendar_state END,
            import_job_id = NULL
        WHERE calendar_state IN ('in_queue', 'in_worker') OR import_job_id IS NOT NULL
      SQL
    end
  end

  def down; end
end
