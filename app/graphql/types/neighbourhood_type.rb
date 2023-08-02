# frozen_string_literal: true

module Types
  DateTimeType = GraphQL::Types::ISO8601Date

  class NeighbourhoodType < Types::BaseObject
    description 'A political divison, for example as established by the UK Boundary Authority. Can be on a number of scales from local to national'

    # field :id, ID, null: false
    field :name, String,
          null: false,
          description: 'The common name for this region'

    field :abbreviated_name, String,
          description: 'Abbreviated version of name or just the name if this is not set'

    field :unit, String,
          description: 'Size of neighbourhood: country -> region -> county -> district -> ward'

    field :unit_name, String,
          description: 'Official name of this neighbourhood'

    field :unit_code_key, String,
          description: 'Official key for this neighbourhood'

    field :unit_code_value, String,
          description: 'Official value (ID) of this neighbourhood'

    field :release_date, DateTimeType,
          description: 'Date that the data for this neighbourhood was released'
  end
end
