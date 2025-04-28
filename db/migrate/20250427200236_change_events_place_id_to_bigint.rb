# frozen_string_literal: true

class ChangeEventsPlaceIdToBigint < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :events, :place_id, :bigint
      end

      dir.down do
        change_column :events, :place_id, :integer
      end
    end
  end
end
