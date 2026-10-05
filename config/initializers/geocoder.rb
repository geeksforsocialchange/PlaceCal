# frozen_string_literal: true

if Rails.env.local?
  # Load the NormalIsland data module (POSTCODES, WARDS, etc.) referenced by
  # the custom geocoder lookup. Without this the constant is undefined outside
  # the seed scripts, raising "uninitialized constant NormalIsland" when the
  # admin partner form geocodes an address.
  require 'normal_island'
  require 'normal_island/geocoder_lookup'
  Geocoder::Lookup.street_services.unshift(:normal_island)
  Geocoder.configure(lookup: :normal_island, timeout: 5)
else
  Geocoder.configure(lookup: :postcodes_io, timeout: 5)
end
