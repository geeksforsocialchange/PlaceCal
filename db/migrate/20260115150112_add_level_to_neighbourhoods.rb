# frozen_string_literal: true

class AddLevelToNeighbourhoods < ActiveRecord::Migration[7.2]
  def change
    add_column :neighbourhoods, :level, :integer
    add_index :neighbourhoods, :level

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE neighbourhoods SET level = CASE unit
            WHEN 'country' THEN 5
            WHEN 'region' THEN 4
            WHEN 'county' THEN 3
            WHEN 'district' THEN 2
            WHEN 'ward' THEN 1
            ELSE 0
          END
        SQL
      end
    end
  end
end
