# frozen_string_literal: true

module Types
  class SiteType < Types::BaseObject
    description 'Sites represent a collection of neighbourhoods or service areas'

    field :id, ID,
          null: false,
          description: 'Internal reference ID'

    field :name, String,
          null: false,
          description: 'Full name of site'

    field :slug, String,
          null: false,
          description: 'Short unique URL friendly version of name'

    field :domain, String,
          description: 'The public URL that this site can be found on PlaceCal'

    field :description, String,
          description: 'Longer description of site'

    field :neighbourhoods, [NeighbourhoodType],
          description: 'The neighbourhoods that this site encompasses'
  end
end
