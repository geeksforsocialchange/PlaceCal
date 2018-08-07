class RemoveTypeAndAddressFromCalendar < ActiveRecord::Migration[5.1]
  def change
    remove_column :calendars, :type, :string
    remove_column :calendars, :address_id, :integer
    remove_column :calendars, :import_lock_at, :datetime
  end
end
