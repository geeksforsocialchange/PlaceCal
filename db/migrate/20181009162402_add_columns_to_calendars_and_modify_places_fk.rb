class AddColumnsToCalendarsAndModifyPlacesFk < ActiveRecord::Migration[5.1]

  def up
    # copy contact columns partners -> calendars
    # NOTE: Not copying any data over from partners. Staging server had no
    # relevant data to copy. Assuming production the same
    change_table :calendars do |t|
      t.text :partnership_contact_name
      t.text :partnership_contact_email
      t.text :partnership_contact_phone
      t.text :public_contact_name
      t.text :public_contact_email
      t.text :public_contact_phone
    end

    # NOTE: Not mapping places_id to correct partners because it's quicker to
    # do manually than code.
    execute("UPDATE calendars SET place_id = null;")

    remove_foreign_key :calendars, :places
    add_foreign_key :calendars, :partners, column: :place_id
  end


  def down
    execute("UPDATE calendars SET place_id = null;")

    remove_foreign_key :calendars, column: :place_id
    add_foreign_key :calendars, :places

    change_table :calendars do |t|
      t.remove :partnership_contact_name, :partnership_contact_email, :partnership_contact_phone
      t.remove :public_contact_name, :public_contact_email, :public_contact_phone
    end
  end
end
