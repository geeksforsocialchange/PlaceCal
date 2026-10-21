# frozen_string_literal: true

module Types
  class SiteType < Types::BaseObject
    description 'Sites represent a collection of neighbourhoods or service areas'

    field :id, ID,
          null: false,
          description: 'Internal reference ID'

    field :description, String,
          description: 'Longer description of site'

    field :neighbourhoods, [NeighbourhoodType],
          description: 'The neighbourhoods that this site encompasses'

    field :name, String,
          null: false,
          description: 'Full name of site'

    field :slug, String,
          null: false,
          description: 'Short unique URL friendly version of name'

    field :url, String,
          description: 'The public URL that this site can be found on PlaceCal'

    # External API contract: the strings the old url column returned, whose one
    # external site was stored with a trailing slash.
    def url
      object.served_domain? || object.domain.blank? ? object.public_url : "#{object.public_url}/"
    end
  end
end
