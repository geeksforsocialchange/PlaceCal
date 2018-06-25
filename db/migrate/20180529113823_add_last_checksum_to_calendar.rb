class AddLastChecksumToCalendar < ActiveRecord::Migration[5.1]
  def change
    add_column :calendars, :last_checksum, :string
  end
end
