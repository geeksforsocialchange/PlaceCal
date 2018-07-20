class AddCriticalErrorToCalendar < ActiveRecord::Migration[5.1]
  def change
    add_column :calendars, :critical_error, :text
  end
end
