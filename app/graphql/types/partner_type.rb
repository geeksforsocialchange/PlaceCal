module Types
  class PartnerType < Types::BaseObject
    

    description 'A Partner who runs Events'

    # placecalID
    field :id, ID, null: false
    field :name, String, null: false
    field :summary, String
    field :description, String

    field :accessibility_summary, String, method: :accessibility_info

    field :logo, String
    field :address, AddressType

    field :url, String
    field :facebook_page, String, method: :facebook_link
    field :twitter_handle, String, method: :twitter_handle

    field :areas_served, [NeighbourhoodType], method: :service_area_neighbourhoods

    field :contact, ContactType

    field :telephone, String, method: :public_phone
    field :email, String, method: :public_email
    field :contact_name, String, method: :public_name

    field :opening_hours, [OpeningHoursType], null: true

    def contact
      object
    end

    def opening_hours
      JSON.parse object.opening_times
    end

    def logo
      return '' if object.image.blank?

      ActionController::Base.helpers.image_url(object.image.url, skip_pipeline: true) 
    end
  end
end

