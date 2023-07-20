# frozen_string_literal: true

class RemoveDeletedAtFromEvents < ActiveRecord::Migration[5.1]
  def up
    remove_column :events, :deleted_at
  end

  def down
    add_column :events, :deleted_at, :datetime
    add_index :events, :deleted_at
  end
end
