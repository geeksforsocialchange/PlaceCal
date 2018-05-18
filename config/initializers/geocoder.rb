# frozen_string_literal: true

Geocoder.configure(
  google_places_search: {
    api_key: ENV['GOOGLE_API_KEY']
  },
  google_places_details: {
    api_key: ENV['GOOGLE_API_KEY']
  },
  google: {
    api_key: ENV['GOOGLE_API_KEY']
  }
)
