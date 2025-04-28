# frozen_string_literal: true

class ChangeVersionsItemIdToBigint < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :versions, :item_id, :bigint
      end

      dir.down do
        change_column :versions, :item_id, :integer
      end
    end
  end
end
