module Types
  class AddressType < Types::BaseObject

    description 'An address representing a physical location'

    # field :id, ID, null: false
    field :street_address, String
    field :address_locality, String
    field :address_region, String
    field :address_country, String, method: :country_code
    field :postal_code, String, method: :postcode
    field :neighbourhood, NeighbourhoodType

    # TODO: figure out parent and children accessors
    # field :containedInPlace
    # field :containedPlace

    def street_address
      [ 
        object.street_address,
        object.street_address2,
        object.street_address3
      ].reject { |line| (line || '').empty? }.join(', ')
    end

    def address_locality
      object.neighbourhood.name
    end

    def address_region
      object.neighbourhood.region
    end
  end
end

