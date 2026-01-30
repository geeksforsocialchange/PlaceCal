# frozen_string_literal: true

class CleanupInvalidOnlineAddresses < ActiveRecord::Migration[8.1]
  def up
    # Find OnlineAddress records where the URL doesn't start with http:// or https://
    # These were created by a bug in maybe_location_is_link that accepted any string
    invalid_online_addresses = OnlineAddress.where.not("url LIKE 'http://%' OR url LIKE 'https://%'")

    invalid_ids = invalid_online_addresses.pluck(:id)

    if invalid_ids.any?
      say "Found #{invalid_ids.count} invalid OnlineAddress records: #{invalid_online_addresses.pluck(:url).join(', ')}"

      # Clear the online_address_id from any events referencing these invalid records
      # rubocop:disable Rails/SkipsModelValidations
      events_updated = Event.where(online_address_id: invalid_ids).update_all(online_address_id: nil)
      # rubocop:enable Rails/SkipsModelValidations
      say "Cleared online_address_id from #{events_updated} events"

      # Delete the invalid OnlineAddress records
      deleted_count = invalid_online_addresses.delete_all
      say "Deleted #{deleted_count} invalid OnlineAddress records"
    else
      say 'No invalid OnlineAddress records found'
    end
  end

  def down
    # This migration cleans up invalid data - it cannot be reversed
    # The invalid OnlineAddress records should not be recreated
    say 'This migration cannot be reversed - invalid OnlineAddress records were cleaned up'
  end
end
