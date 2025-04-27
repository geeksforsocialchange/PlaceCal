# frozen_string_literal: true

class ChangeSitesNeighbourhoodsNeighbourhoodIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :sites_neighbourhoods, :neighbourhood_id, :bigint
  end

  def down
    change_column :sites_neighbourhoods, :neighbourhood_id, :integer
  end
end
