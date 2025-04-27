# frozen_string_literal: true

class ChangeSitesNeighbourhoodsNeighbourhoodIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    # Step 1: Clean up existing NULLs
    # It's OK for this to not be reversible as they are bad entries we don't want
    execute <<-SQL.squish # rubocop:disable Rails/ReversibleMigration
        DELETE FROM sites_neighbourhoods WHERE neighbourhood_id IS NULL;
    SQL

    # Step 2: Now it's safe to add NOT NULL
    change_column_null :sites_neighbourhoods, :neighbourhood_id, false
  end
end
