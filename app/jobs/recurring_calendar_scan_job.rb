# frozen_string_literal: true

# Self-rescheduling job that scans for calendars needing import.
# Runs inside the job_worker container (which already has Rails loaded),
# avoiding the ~500MB Rails boot that was OOM-killing the cron container.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringCalendarScanJob < ApplicationJob
  INTERVAL = 1.hour

  def perform
    Calendar.queue_all_for_import!
  ensure
    self.class.set(wait: INTERVAL).perform_later
  end
end
