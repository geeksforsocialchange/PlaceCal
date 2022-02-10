module Types
  class EventType < Types::BaseObject

    description 'An Event'

    field :id, ID, null: false
    field :description, String
    field :summary, String

    field :address, AddressType

  end
end

