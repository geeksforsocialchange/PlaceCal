# frozen_string_literal: true

class AddSitesIdSitesNeighbourhoodsSiteIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :sites_neighbourhoods, :sites, column: :site_id, primary_key: :id
  end
end
