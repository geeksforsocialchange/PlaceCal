# frozen_string_literal: true

# Safety net: checks every 6 hours that the other recurring jobs still
# exist in the queue. If a job's re-enqueue failed (e.g. transient DB
# outage during re-enqueue, or DJ exhausting retries), this re-seeds it.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringWatchdogJob < ApplicationJob
  include SelfRescheduling

  INTERVAL = 6.hours

  WATCHED_JOBS = [RecurringCalendarScanJob, RecurringMaintenanceJob].freeze

  def perform
    run do
      WATCHED_JOBS.each do |job_class|
        next if Delayed::Job.exists?(['handler LIKE ?', "%#{job_class.name}%"])

        job_class.perform_later
        Rails.logger.warn("[Watchdog] Re-seeded missing #{job_class.name}")
      end
    end
  end
end
