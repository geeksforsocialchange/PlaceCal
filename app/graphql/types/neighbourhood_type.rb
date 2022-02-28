module Types
  class NeighbourhoodType < Types::BaseObject

    description 'A physical region of country'

    field :id, ID, null: false
    field :name, String, null: false

    field :parent, NeighbourhoodType
    field :children, NeighbourhoodType

  end
end

