class RemoveDeletedAtFromEvents < ActiveRecord::Migration[5.1]
  def up
    Event.where.not(deleted_at: nil).destroy_all
    remove_column :events, :deleted_at
  end

  def down
    add_column :events, :deleted_at, :datetime, index: true
  end
end
