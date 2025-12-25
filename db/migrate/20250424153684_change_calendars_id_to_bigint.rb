# frozen_string_literal: true

class ChangeCalendarsIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :calendars, :id, :bigint
  end

  def down
    change_column :calendars, :id, :integer
  end
end
