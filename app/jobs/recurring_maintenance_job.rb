# frozen_string_literal: true

# Self-rescheduling job that runs daily maintenance tasks.
# Replaces the cron-based rake tasks that were OOM-killing.
#
# Seeded on boot by config/initializers/recurring_jobs.rb
class RecurringMaintenanceJob < ApplicationJob
  INTERVAL = 1.day

  def perform
    deduplicate_events
    refresh_counters
    clean_orphaned_addresses
  ensure
    self.class.set(wait: INTERVAL).perform_later
  end

  private

  # Same logic as events:deduplicate rake task
  def deduplicate_events
    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      WITH duplicates AS (
        SELECT id, ROW_NUMBER() OVER (
          PARTITION BY uid, dtstart, dtend, calendar_id
          ORDER BY id
        ) as rn
        FROM events
      )
      DELETE FROM events WHERE id IN (
        SELECT id FROM duplicates WHERE rn > 1
      )
    SQL
    deleted = result.cmd_tuples
    Rails.logger.info("RecurringMaintenanceJob: deduplicated #{deleted} events") if deleted.positive?
  end

  # Same logic as counters:refresh_all rake task
  def refresh_counters
    Site.refresh_all_counts!
    Neighbourhood.refresh_partners_count!
  end

  # Same logic as db:clean_bad_addresses rake task
  def clean_orphaned_addresses
    in_use_ids = Set.new(Partner.pluck(:address_id).compact) |
                 Set.new(Event.pluck(:address_id).compact)

    orphaned = Address.where.not(id: in_use_ids)
    count = orphaned.count
    return unless count.positive?

    orphaned.in_batches(of: 1000).delete_all
    Rails.logger.info("RecurringMaintenanceJob: deleted #{count} orphaned addresses")
  end
end
