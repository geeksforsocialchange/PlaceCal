module Types
  class SiteType < Types::BaseObject

    description 'Sites represent a collection of neighbourhoods or service areas'

    field :id, ID, null: false
    field :name, String, null: false
    field :slug, String, null: false

    field :domain, String
    field :description, String

    field :neighbourhoods, [NeighbourhoodType]

    # field :partners, [PartnerType]
    
    # t.datetime "created_at", null: false
    # t.datetime "updated_at", null: false
    # t.bigint "site_admin_id"
    # t.string "logo"
    # t.string "hero_image"
    # t.string "hero_image_credit"
    # t.string "footer_logo"
    # t.string "tagline", default: "The Community Calendar"
    # t.string "place_name"
    # t.string "theme"
    # t.boolean "is_published", default: false
    # t.string "badge_zoom_level"

  end
end

