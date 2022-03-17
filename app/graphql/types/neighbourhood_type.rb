module Types
  class NeighbourhoodType < Types::BaseObject

    description 'A region of physical space that may have sub-regions within'

    # field :id, ID, null: false
    field :name, String, 
      null: false,
      description: 'The common name for this region'

    field :abbreviated_name, String,
      method: :name_abbr,
      description: 'Shorthand version of name in common use'

    field :unit, String,
      description: 'Size of neighbourhood: country -> region -> county -> district -> ward'

    field :unit_name, String,
      description: 'from postcode.io'

    field :unit_code_key, String,
      description: 'from postcode.io'

    field :unit_code_value, String,
      description: 'from postcode.io'

  end
end

