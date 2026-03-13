# frozen_string_literal: true

# Seed self-rescheduling jobs on boot if they're not already queued.
# These replace the cron-based rake tasks that were OOM-killing the cron
# container (128MB was not enough to boot Rails for each task).
#
# Each job re-enqueues itself after completion, so they only need
# seeding once. This initializer ensures they exist after deploys.

Rails.application.config.after_initialize do
  next unless Rails.env.production? || Rails.env.staging? # rubocop:disable Rails/UnknownEnv
  next unless defined?(Delayed::Job)

  begin
    next unless Delayed::Job.table_exists?
  rescue ActiveRecord::NoDatabaseError
    next
  end

  [RecurringCalendarScanJob, RecurringMaintenanceJob].each do |job_class|
    unless Delayed::Job.exists?(['handler LIKE ?', "%#{job_class.name}%"])
      job_class.perform_later
      Rails.logger.info("Seeded #{job_class.name}")
    end
  end
end
