module Types
  class AddressType < Types::BaseObject

    description 'An address representing a physical location'

    # field :id, ID, null: false
    field :street_address, String, 
      method: :full_street_address,
      description: 'The first few lines of the address like: 123 Road, Eastleigh, Southampton'

    field :address_locality, String,
      description: 'The ward this address is in'

    field :address_region, String,
      description: 'The district this address is in'

    field :address_country, String, 
      method: :country_code,
      description: 'The country of this event (England, Scotland, Wales, or Northern Ireland)'

    field :postal_code, String, 
      method: :postcode,
      description: 'A UK postcode'

    field :neighbourhood, NeighbourhoodType,
      description: 'The neighbourhood of this address (see neighbourhood type)'

    # TODO: figure out parent and children accessors
    # field :containedInPlace
    # field :containedPlace

    def address_locality
      object.neighbourhood.name
    end

    def address_region
      object.neighbourhood.region
    end
  end
end

