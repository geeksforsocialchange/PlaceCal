# frozen_string_literal: true

class RemoveIndexSitesNeighbourhoodsNeighbourhoodIdIndex < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        remove_index 'sites_neighbourhoods', name: 'index_sites_neighbourhoods_neighbourhood_id'
      end

      dir.down do
        add_index 'sites_neighbourhoods', :neighbourhood_id, name: 'index_sites_neighbourhoods_neighbourhood_id'
      end
    end
  end
end
