# frozen_string_literal: true

class ChangeVersionsItemIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :versions, :item_id, :bigint
  end

  def down
    change_column :versions, :item_id, :integer
  end
end
