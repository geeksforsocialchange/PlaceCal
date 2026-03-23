# frozen_string_literal: true

# Seed self-rescheduling jobs on boot if they're not already queued.
# These replace the cron-based rake tasks that were OOM-killing the cron
# container (128MB was not enough to boot Rails for each task).
#
# Each job re-enqueues itself after completion, so they only need
# seeding once. This initializer ensures they exist after deploys.
#
# The watchdog job periodically verifies the other two still exist,
# re-seeding any that dropped out (e.g. due to a transient DB outage
# during re-enqueue, or DJ exhausting retries on a failed job).

Rails.application.config.after_initialize do
  next unless Rails.env.production? || Rails.env.staging? # rubocop:disable Rails/UnknownEnv
  next unless defined?(Delayed::Job)

  begin
    next unless Delayed::Job.table_exists?
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    next
  end

  [RecurringCalendarScanJob, RecurringMaintenanceJob, RecurringWatchdogJob].each do |job_class|
    unless Delayed::Job.exists?(['handler LIKE ?', "%#{job_class.name}%"])
      job_class.perform_later
      Rails.logger.info("Seeded #{job_class.name}")
    end
  end
end
