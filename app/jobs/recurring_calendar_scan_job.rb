# frozen_string_literal: true

# Self-rescheduling job that scans for calendars needing import.
# Runs inside the job_worker container (which already has Rails loaded),
# avoiding the ~500MB Rails boot that was OOM-killing the cron container.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringCalendarScanJob < ApplicationJob
  include SelfRescheduling

  INTERVAL = 1.hour

  def perform
    run do
      Appsignal::CheckIn.cron('calendar_scan') do
        Calendar.queue_all_for_import!
      end
    end
  end
end
