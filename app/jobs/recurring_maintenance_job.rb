# frozen_string_literal: true

# Daily clean-up and refreshes (config/recurring.yml)
class RecurringMaintenanceJob < ApplicationJob
  # Overlaps the last run, so a failed one's URLs still go out; sending a URL twice does no harm
  SUBMISSION_WINDOW = 2.days

  def perform
    Appsignal::CheckIn.cron('daily_maintenance') do
      Event.prune_old_versions!
      Site.refresh_all_counts!
      Neighbourhood.refresh_partners_count!
      Address.delete_orphaned!
      CarrierWave.clean_cached_files!
      IndexNowSubmission.new(since: SUBMISSION_WINDOW.ago).call if Rails.env.production?
    end
  end
end
