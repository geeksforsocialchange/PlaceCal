class RenameEventsLocationColumn < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :location, :raw_location_from_source
  end
end
