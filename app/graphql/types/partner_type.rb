module Types
  class PartnerType < Types::BaseObject

    description 'A Partner who runs Events'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String
    field :summary, String

    field :url, String
  end
end

