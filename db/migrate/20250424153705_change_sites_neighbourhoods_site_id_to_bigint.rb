# frozen_string_literal: true

class ChangeSitesNeighbourhoodsSiteIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :sites_neighbourhoods, :site_id, :bigint
  end

  def down
    change_column :sites_neighbourhoods, :site_id, :integer
  end
end
