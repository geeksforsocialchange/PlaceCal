module Types
  class EventType < Types::BaseObject

    description 'An Event that is run by a Parter on a date at a given Address'

    field :id, ID, null: false
    field :description, String
    field :summary, String

    field :address, AddressType

  end
end

