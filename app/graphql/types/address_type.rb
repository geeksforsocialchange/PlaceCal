module Types
  class AddressType < Types::BaseObject

    description 'An address representing a physical building'

    # field :id, ID, null: false
    field :street_address, String
    field :street_address2, String
    field :street_address3, String
    field :city, String
    field :postcode, String
    field :country_code, String
    field :full_street_address, String
    field :all_address_lines, [String]
  end
end

