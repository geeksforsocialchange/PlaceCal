# frozen_string_literal: true

# DEPRECATED: All recurring tasks have been moved to self-scheduling jobs
# (RecurringCalendarScanJob and RecurringMaintenanceJob) that run inside
# the job_worker container. This avoids the ~500MB Rails boot that was
# OOM-killing the cron container.
#
# The cron container has been removed from deploy.yml.
# These rake tasks still work for manual use (e.g. local development).
#
# See config/initializers/recurring_jobs.rb for the seeding logic.
# See also: #3013 for future migration to Solid Queue recurring tasks.
