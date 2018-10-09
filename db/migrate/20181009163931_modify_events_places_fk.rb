class ModifyEventsPlacesFk < ActiveRecord::Migration[5.1]
  def up
    # NOTE: Nulling this data in order to make the foreign key change work but
    # we'll actually need to delete and reimport all events in order to have
    # valid data again.
    execute("UPDATE events SET place_id = null;")

    remove_foreign_key :events, :places
    add_foreign_key :events, :partners, column: :place_id
  end


  def down
    execute("UPDATE events SET place_id = null;")

    remove_foreign_key :events, column: :place_id
    add_foreign_key :events, :places
  end
end
