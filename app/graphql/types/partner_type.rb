module Types
  class PartnerType < Types::BaseObject

    description 'A Partner who runs Events'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String
    field :summary, String

    field :url, String

    field :contact_info, ContactInfoType 
    
    def contact_info
      {
        name: object.public_name,
        phone: object.public_phone,
        email: object.public_email
      }
    end
  end
end

