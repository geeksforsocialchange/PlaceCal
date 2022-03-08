module Types
  class PartnerType < Types::BaseObject

    description 'A Partner who runs Events'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String
    field :summary, String

    field :url, String
    field :twitter, String, method: :twitter_handle
    field :facebook, String, method: :facebook_link

    field :telephone, String, method: :public_phone
    field :email, String, method: :public_email
    field :contact_name, String, method: :public_name
  end
end

