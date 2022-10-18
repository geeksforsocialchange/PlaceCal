# frozen_string_literal: true

class AddAncestryToNeighbourhoods < ActiveRecord::Migration[6.0]
  def change
    add_column :neighbourhoods, :ancestry, :string
    add_index :neighbourhoods, :ancestry
  end
end
