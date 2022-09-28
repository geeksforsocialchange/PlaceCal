# frozen_string_literal: true

module Types
  class GeoCoordinatesType < Types::BaseObject
    description "The geo coordinates of the partner's address."

    field :latitude,
          String,
          description: "The latitude of the partner's address"

    field :longitude,
          String,
          description: "The longitude of the partner's address"

    def latitude
      object&.latitude
    end

    def longitude
      object&.longitude
    end
  end
end
