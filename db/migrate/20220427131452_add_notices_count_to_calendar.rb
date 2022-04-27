class AddNoticesCountToCalendar < ActiveRecord::Migration[6.1]
  def change
    add_column :calendars, :notice_count, :integer
  end
end
