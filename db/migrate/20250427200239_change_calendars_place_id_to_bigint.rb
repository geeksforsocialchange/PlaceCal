# frozen_string_literal: true

class ChangeCalendarsPlaceIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :calendars, :place_id, :bigint
  end

  def down
    change_column :calendars, :place_id, :integer
  end
end
