# frozen_string_literal: true

class ChangeCalendarsPlaceIdToBigint < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :calendars, :place_id, :bigint
      end

      dir.down do
        change_column :calendars, :place_id, :integer
      end
    end
  end
end
