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

    # max_old_partner_id = execute("SELECT max(id) from partners;").first['max']

    # # 2) copy places data to the partners table

    # # Where slugs would prevent insertion of a new row, change the existing slug
    # execute( "UPDATE partners SET slug = slug || '-old' " \
    #   "WHERE slug IN " \
    #   "(SELECT partners.slug FROM partners JOIN places ON partners.slug = places.slug);"
    # )

    # execute("INSERT INTO partners " \
    #   "(name, short_description, address_id, created_at, updated_at, url, image, public_phone, public_email, opening_times, booking_info, accessibility_info, is_a_place, slug) " \
    #   "SELECT name, short_description, address_id, created_at, updated_at, url, logo, phone, email, opening_times, booking_info, accessibility_info, true, slug " \
    #   "FROM places " \
    #   "ORDER BY id;" # <- Doing this to ensure that places are inserted into partners lowest ID first
    # )

    # # Map old place ids to new partner ids
    # pp_map = execute(
    #   "SELECT places.id as old_place_id, partners.id as new_partner_id " \
    #   "FROM partners JOIN places ON partners.name = places.name " \
    #   "WHERE partners.id > #{max_old_partner_id} " \
    #   "ORDER BY old_place_id DESC;"  # <- Doing this to ensure that lowest numbered places are replaced last in case there is overlap in the ranges of old_place_id and new_partner_id
    # )

    # 3) Point calendars.place_id at the partners table and set appropriate values.
    remove_foreign_key :calendars, :places

    # pp_map.each do |pp|
    #   execute("UPDATE calendars SET place_id = #{pp['new_partner_id']} " \
    #     "WHERE place_id = #{pp['old_place_id']};"
    #   )
    # end

    add_foreign_key :calendars, :partners, column: :place_id

    # 4) Point events.place_id at the partners table and set appropriate values.
    remove_foreign_key :events, :places

    # pp_map.each do |pp|
    #   execute("UPDATE events SET place_id = #{pp['new_partner_id']} " \
    #     "WHERE place_id = #{pp['old_place_id']};"
    #   )
    # end

    add_foreign_key :events, :partners, column: :place_id
  end

  def down
    # 4)
    execute('UPDATE events SET place_id = null;')

    remove_foreign_key :events, column: :place_id
    add_foreign_key :events, :places

    # 3)
    execute('UPDATE calendars SET place_id = null;')

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
