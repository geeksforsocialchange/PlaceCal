# frozen_string_literal: true

class ChangeSitesNeighbourhoodsNeighbourhoodIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    # Step 1: Clean up existing NULLs (only on migrate up, not down)
    up_only do
      execute <<~SQL.squish
        DELETE FROM sites_neighbourhoods WHERE neighbourhood_id IS NULL;
      SQL
    end

    # Step 2: Now it's safe to add NOT NULL
    change_column_null :sites_neighbourhoods, :neighbourhood_id, false
  end
end
