# frozen_string_literal: true

class AddNeighbourhoodsIdSitesNeighbourhoodsNeighbourhoodIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :sites_neighbourhoods, :neighbourhoods, column: :neighbourhood_id, primary_key: :id
  end
end
