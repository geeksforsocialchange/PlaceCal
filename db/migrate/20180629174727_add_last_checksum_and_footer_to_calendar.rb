class AddLastChecksumAndFooterToCalendar < ActiveRecord::Migration[5.1]
  def change
    add_column :calendars, :last_checksum, :string
    add_column :calendars, :footer, :text
  end
end
