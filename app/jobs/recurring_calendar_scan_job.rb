# frozen_string_literal: true

# Queues every calendar for import, hourly (config/recurring.yml)
class RecurringCalendarScanJob < ApplicationJob
  def perform
    Appsignal::CheckIn.cron('calendar_scan') do
      # Recover orphaned busy calendars first so this same pass requeues them.
      Calendar.reset_stuck_imports!
      Calendar.queue_all_for_import!
    end
  end
end
