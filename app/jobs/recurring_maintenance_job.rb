# frozen_string_literal: true

# Self-rescheduling job that runs daily maintenance tasks.
# Replaces the cron-based rake tasks that were OOM-killing.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringMaintenanceJob < ApplicationJob
  include SelfRescheduling

  INTERVAL = 1.day

  def perform
    run do
      Appsignal::CheckIn.cron('daily_maintenance') do
        Event.deduplicate!
        Site.refresh_all_counts!
        Neighbourhood.refresh_partners_count!
        Address.delete_orphaned!
      end
    end
  end
end
