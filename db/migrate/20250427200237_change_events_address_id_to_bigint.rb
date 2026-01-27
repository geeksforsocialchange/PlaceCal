# frozen_string_literal: true

class ChangeEventsAddressIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :events, :address_id, :bigint
  end

  def down
    change_column :events, :address_id, :integer
  end
end
