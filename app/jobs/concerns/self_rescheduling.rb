# frozen_string_literal: true

# Mixin for jobs that re-enqueue themselves on a fixed interval.
#
# Include this, set INTERVAL on your job class, and call `run { ... }`
# instead of putting work directly in `perform`. The concern handles:
#
#   - Re-enqueuing the next run after successful completion
#   - Retrying the re-enqueue if the DB is temporarily unreachable
#   - Logging when re-enqueue permanently fails
#
# On failure, the job is NOT re-enqueued — Delayed::Job's built-in retry
# handles that. This avoids duplicate chains (ensure + DJ retry = 2 copies
# that multiply exponentially). If DJ exhausts retries, the watchdog
# re-seeds the missing job.
#
# Example:
#   class MyRecurringJob < ApplicationJob
#     include SelfRescheduling
#     INTERVAL = 1.hour
#
#     def perform
#       run { do_work }
#     end
#   end
module SelfRescheduling
  extend ActiveSupport::Concern

  RESCHEDULE_ATTEMPTS = 3
  RESCHEDULE_DELAY = 5 # seconds

  def run
    yield
    reschedule!
  end

  private

  def reschedule!
    attempts = 0
    begin
      self.class.set(wait: self.class::INTERVAL).perform_later
    rescue StandardError => e
      attempts += 1
      if attempts < RESCHEDULE_ATTEMPTS
        sleep RESCHEDULE_DELAY
        retry
      end
      Rails.logger.error("[#{self.class.name}] Failed to reschedule after #{RESCHEDULE_ATTEMPTS} attempts: #{e.message}")
    end
  end
end
