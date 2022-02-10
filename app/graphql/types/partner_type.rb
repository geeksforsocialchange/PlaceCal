module Types
  class PartnerType < Types::BaseObject

    description 'A partner'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String
    field :summary, String

    field :url, String
  end
end

