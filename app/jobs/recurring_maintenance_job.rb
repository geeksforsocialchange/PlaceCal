# frozen_string_literal: true

# Self-rescheduling job that runs daily maintenance tasks.
# Replaces the cron-based rake tasks that were OOM-killing.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringMaintenanceJob < ApplicationJob
  INTERVAL = 1.day

  def perform
    Event.deduplicate!
    Site.refresh_all_counts!
    Neighbourhood.refresh_partners_count!
    Address.delete_orphaned!
  ensure
    self.class.set(wait: INTERVAL).perform_later
  end
end
