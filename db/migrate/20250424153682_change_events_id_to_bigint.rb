# frozen_string_literal: true

class ChangeEventsIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :events, :id, :bigint
  end

  def down
    change_column :events, :id, :integer
  end
end
