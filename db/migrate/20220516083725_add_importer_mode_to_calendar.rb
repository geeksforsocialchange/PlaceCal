class AddImporterModeToCalendar < ActiveRecord::Migration[6.1]
  def change
    add_column :calendars, :importer_mode, :string, default: "auto"
    add_column :calendars, :importer_used, :string
  end
end
