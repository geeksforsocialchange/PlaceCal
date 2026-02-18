# frozen_string_literal: true

if Rails.env.local?
  require 'normal_island/geocoder_lookup'
  Geocoder::Lookup.street_services.unshift(:normal_island)
  Geocoder.configure(lookup: :normal_island, timeout: 5)
else
  Geocoder.configure(lookup: :postcodes_io, timeout: 5)
end
