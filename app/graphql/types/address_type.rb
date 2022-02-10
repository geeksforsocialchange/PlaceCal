module Types
  class AddressType < Types::BaseObject

    description 'A partner'

    # field :id, ID, null: false
    field :street_address, String
    field :street_address2, String
    field :street_address3, String
    field :city, String
    field :postcode, String
    field :country_code, String
  end
end

