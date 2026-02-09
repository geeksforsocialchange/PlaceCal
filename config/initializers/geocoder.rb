# frozen_string_literal: true

require 'normal_island/geocoder_lookup'

# Register the Normal Island lookup so Geocoder recognises :normal_island
Geocoder::Lookup.street_services.unshift(:normal_island)

Geocoder.configure(
  lookup: :normal_island,
  timeout: 5
)
