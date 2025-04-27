# frozen_string_literal: true

class AddSitesNeighbourhoodsSiteIdIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :sites_neighbourhoods, :site_id, name: :index_sites_neighbourhoods_site_id
  end
end
