class ChangeCalendarColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :calendars, :footer, :text
    add_column :calendars, :is_working, :boolean, default: true, null: false
  end
end
