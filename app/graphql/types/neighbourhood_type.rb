module Types
  class NeighbourhoodType < Types::BaseObject

    description 'A physical region of country'

    # field :id, ID, null: false
    field :name, String, null: false
    field :abbreviated_name, String, method: :name_abbr
    field :unit, String
    field :unit_name, String
    field :unit_code_key, String
    field :unit_code_value, String
  end
end

