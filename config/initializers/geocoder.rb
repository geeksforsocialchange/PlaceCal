# frozen_string_literal: true

Geocoder.configure(

  lookup: :postcodes_io,

  timeout: 5
  
  # google_places_search: {
  #   api_key: ENV['GOOGLE_API_KEY']
  # },
  # google_places_details: {
  #   api_key: ENV['GOOGLE_API_KEY']
  # },
  # google: {
  #   api_key: ENV['GOOGLE_API_KEY']
  # }
)
