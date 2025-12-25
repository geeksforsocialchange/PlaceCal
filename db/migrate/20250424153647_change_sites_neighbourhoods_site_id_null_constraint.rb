# frozen_string_literal: true

class ChangeSitesNeighbourhoodsSiteIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sites_neighbourhoods, :site_id, false
  end
end
