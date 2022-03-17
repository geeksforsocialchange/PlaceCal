module Types
  class PartnerType < Types::BaseObject
    

    description 'Organisations that run events'

    field :id, ID, 
      null: false,
      description: 'ID of partner'

    field :name, String, 
      null: false,
      description: 'A short string about this partner, an alias for `summary`'

    field :summary, String,
      description: 'A short string describing partner'

    field :description, String,
      description: 'Longer text about partner with more detail (in Markdown syntax)'

    field :accessibility_summary, String,
      method: :accessibility_info,
      description: 'Information about this Partner\'s accessibility'

    field :logo, String,
      description: 'The URL of the logo that is served from PlaceCal'

    field :address, AddressType,
      description: 'The physical address of this partner'

    field :url, String,
      description: 'The URL provided by the partner for users to find out more info'

    field :facebook_page, String,
      method: :facebook_link,
      description: 'The possible facebook URL of this partner'

    field :twitter_url, String, 
      method: :twitter_handle,
      description: 'The URL to the partner\'s twitter profile'

    field :areas_served, [NeighbourhoodType],
      method: :service_area_neighbourhoods,
      description: 'Areas served by partner that are not at a physical address'

    field :contact, ContactType,
      description: 'Venue contact information - could be a person or a general contact'

    # field :telephone, String, method: :public_phone
    # field :email, String, method: :public_email
    # field :contact_name, String, method: :public_name

    field :opening_hours, [OpeningHoursType], 
      null: true,
      description: 'The hours that this partner opens for at their physical address'

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

    def twitter_url
      "https://twitter.com/#{object.twitter_handle}" if object.twitter_handle
    end
  end
end

