class RemoveTypeAndAddressFromCalendar < ActiveRecord::Migration[5.1]
  def change
    remove_column :calendars, :type, :string
    remove_column :calendars, :address_id, :integer
  end
end
