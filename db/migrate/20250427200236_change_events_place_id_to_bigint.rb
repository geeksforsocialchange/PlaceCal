# frozen_string_literal: true

class ChangeEventsPlaceIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :events, :place_id, :bigint
  end

  def down
    change_column :events, :place_id, :integer
  end
end
