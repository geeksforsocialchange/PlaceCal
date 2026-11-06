# frozen_string_literal: true

# Self-rescheduling job that runs daily maintenance tasks.
# Replaces the cron-based rake tasks that were OOM-killing.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringMaintenanceJob < ApplicationJob
  include SelfRescheduling

  INTERVAL = 1.day
  # Runs drift and can fail, and sending a URL twice does no harm.
  SUBMISSION_WINDOW = 2.days

  def perform
    run do
      Appsignal::CheckIn.cron('daily_maintenance') do
        Event.deduplicate!
        Event.prune_old_versions!
        Site.refresh_all_counts!
        Neighbourhood.refresh_partners_count!
        Address.delete_orphaned!
        IndexNowSubmission.new(since: SUBMISSION_WINDOW.ago).call if Rails.env.production?
      end
    end
  end
end
