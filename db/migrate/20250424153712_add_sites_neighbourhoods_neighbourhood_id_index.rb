# frozen_string_literal: true

class AddSitesNeighbourhoodsNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :sites_neighbourhoods, :neighbourhood_id, name: :index_sites_neighbourhoods_neighbourhood_id
  end
end
