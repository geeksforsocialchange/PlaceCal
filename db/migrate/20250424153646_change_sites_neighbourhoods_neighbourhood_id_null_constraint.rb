# frozen_string_literal: true

class ChangeSitesNeighbourhoodsNeighbourhoodIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites_neighbourhoods, :neighbourhood_id, false
  end
end
