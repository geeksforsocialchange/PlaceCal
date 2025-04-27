# frozen_string_literal: true

class AddSitesNeighbourhoodsNeighbourhoodIdSiteIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :sites_neighbourhoods, %w[neighbourhood_id site_id], name: :index_sites_neighbourhoods_neighbourhood_id_site_id, unique: true
  end
end
