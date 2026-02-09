# frozen_string_literal: true

class AddPartnersCountToNeighbourhoods < ActiveRecord::Migration[7.2]
  def change
    add_column :neighbourhoods, :partners_count, :integer, default: 0, null: false
    add_index :neighbourhoods, :partners_count

    reversible do |dir|
      dir.up do
        # Backfill partner counts using efficient SQL
        execute <<~SQL.squish
          UPDATE neighbourhoods SET partners_count = (
            SELECT COUNT(DISTINCT p.id)
            FROM addresses a
            JOIN partners p ON p.address_id = a.id
            WHERE a.neighbourhood_id = neighbourhoods.id
          ) + (
            SELECT COUNT(DISTINCT sa.partner_id)
            FROM service_areas sa
            WHERE sa.neighbourhood_id = neighbourhoods.id
          )
        SQL
      end
    end
  end
end
