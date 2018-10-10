class MergePartnersPlacesTables < ActiveRecord::Migration[5.1]

  # NOTE: No data deletion happens in this migration. The only destructive edits
  # are dropping of indexes in order to make other changes possible.
  def up

    # 1) add relevant places columns to partners and rename other where appropriate
    change_table :partners do |t|
      t.jsonb :opening_times
      t.text :booking_info
      t.text :accessibility_info
    end

    max_old_partner_id = execute("SELECT max(id) from partners;").first['max']

    # 2) copy places data to the partners table
    # do not copy slugs because they will violate uniqueness for some rows
    execute(
%(INSERT INTO partners (name, short_description, address_id, created_at, updated_at, url, image, public_phone, public_email, opening_times, booking_info, accessibility_info, is_a_place)
SELECT name, short_description, address_id, created_at, updated_at, url, logo, phone, email, opening_times, booking_info, accessibility_info, true
FROM places;)
    )

    # Map old place ids to new partner ids
    pp_map = execute(
%(SELECT places.id as old_place_id, partners.id as new_partner_id
FROM partners JOIN places ON partners.name = places.name
WHERE partners.id > #{max_old_partner_id};)
    )

    # 3) Point calendars.place_id at the partners table and set appropriate values.
    execute("UPDATE calendars SET place_id = null;")

    remove_foreign_key :calendars, :places
    add_foreign_key :calendars, :partners, column: :place_id

    pp_map.each do |pp|
      execute("UPDATE calendars SET place_id = #{pp['new_partner_id']} WHERE place_id = #{pp['old_place_id']};")
    end
  end


  def down

    #3)
    execute("UPDATE calendars SET place_id = null;")

    remove_foreign_key :calendars, column: :place_id
    add_foreign_key :calendars, :places

    # 2)
    # Cannot delete rows. How would we idenitfy the migrated ones?

    # 1)
    change_table :partners do |t|
      t.remove :opening_times, :booking_info, :accessibility_info
    end
  end
end
