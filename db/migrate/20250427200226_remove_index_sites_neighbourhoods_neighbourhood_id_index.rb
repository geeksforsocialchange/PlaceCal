# frozen_string_literal: true

class RemoveIndexSitesNeighbourhoodsNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def up
    remove_index 'sites_neighbourhoods', name: 'index_sites_neighbourhoods_neighbourhood_id'
  end

  def down
    add_index 'sites_neighbourhoods', :neighbourhood_id, name: 'index_sites_neighbourhoods_neighbourhood_id'
  end
end
