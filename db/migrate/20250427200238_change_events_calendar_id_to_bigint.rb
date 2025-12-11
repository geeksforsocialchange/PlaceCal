# frozen_string_literal: true

class ChangeEventsCalendarIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :events, :calendar_id, :bigint
  end

  def down
    change_column :events, :calendar_id, :integer
  end
end
