# frozen_string_literal: true

namespace :addresses do
  desc 'Re-geocode addresses with stale or missing neighbourhoods'
  task regeocde: :environment do
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
end
