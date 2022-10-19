# frozen_string_literal: true

class AddParentNameFieldToNeighbourhoods < ActiveRecord::Migration[6.1]
  def change
    add_column :neighbourhoods, :parent_name, :string

    Neighbourhood.find_each(&:save)
  end
end
