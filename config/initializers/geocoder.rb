# frozen_string_literal: true

require 'normal_island/geocoder_lookup'

# Use the Normal Island geocoder lookup as the primary lookup in all environments.
# It handles ZZ-prefix postcodes locally (for dev seeds and tests) and delegates
# all other postcodes to the real postcodes.io API — so production is unaffected.
Geocoder::Lookup.street_services.unshift(:normal_island)

Geocoder.configure(
  lookup: :normal_island,
  timeout: 5
)
