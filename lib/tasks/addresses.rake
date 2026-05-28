# frozen_string_literal: true

namespace :addresses do
  desc 'Re-geocode addresses with stale or missing neighbourhoods'
  task regeocode: :environment do
    latest = Neighbourhood::LATEST_RELEASE_DATE

    # Find in-use addresses (linked to a partner or event) with stale neighbourhoods
    in_use_ids = Set.new(Partner.pluck(:address_id).compact) +
                 Set.new(Event.pluck(:address_id).compact)

    stale = Address.where(id: in_use_ids).where(
      'neighbourhood_id IS NULL OR neighbourhood_id IN (?)',
      Neighbourhood.where(release_date: ...latest).select(:id)
    )

    total = stale.count
    puts "Found #{total} in-use addresses with stale or missing neighbourhoods"

    updated = 0
    failed = 0
    skipped = 0

    stale.find_each do |address|
      res = Geocoder.search(address.postcode).first&.data
      if res.nil?
        puts "  SKIP #{address.id} (#{address.postcode}) - postcode not found"
        skipped += 1
        next
      end

      neighbourhood = Neighbourhood.find_from_postcodesio_response(res)
      if neighbourhood.nil?
        puts "  FAIL #{address.id} (#{address.postcode}) - no neighbourhood match"
        failed += 1
        next
      end

      address.update_columns( # rubocop:disable Rails/SkipsModelValidations
        neighbourhood_id: neighbourhood.id,
        latitude: res['latitude'],
        longitude: res['longitude']
      )
      updated += 1
    end

    puts "Done: #{updated} updated, #{failed} failed, #{skipped} skipped (of #{total} total)"
  end

  desc 'Backfill the city field on addresses missing one from postcodes.io'
  task backfill_city: :environment do
    # postcodes.io has no hard published rate limit but asks for reasonable use.
    # Pause briefly between requests to stay polite when backfilling in bulk.
    sleep_seconds = Float(ENV.fetch('POSTCODES_IO_SLEEP', '0.1'))

    scope = Address.needs_city_backfill
    total = scope.count
    puts "Found #{total} addresses needing a city backfill"

    updated = 0
    not_found = 0
    blank = 0

    scope.find_each do |address|
      case address.backfill_city!
      when :updated
        updated += 1
      when :not_found
        puts "  SKIP #{address.id} (#{address.postcode}) - postcode not found"
        not_found += 1
      when :blank
        puts "  SKIP #{address.id} (#{address.postcode}) - no admin_district in response"
        blank += 1
      end

      sleep sleep_seconds if sleep_seconds.positive?
    end

    puts "Done: #{updated} updated, #{not_found} not found, #{blank} no district (of #{total} total)"
  end
end
