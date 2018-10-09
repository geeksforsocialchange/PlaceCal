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

    # 2) copy places data to the partners table
    # do not copy slugs because they will violate uniqueness for some rows
    execute(
%(INSERT INTO partners (name, short_description, address_id, created_at, updated_at, url, image, public_phone, public_email, opening_times, booking_info, accessibility_info, is_a_place)
SELECT name, short_description, address_id, created_at, updated_at, url, logo, phone, email, opening_times, booking_info, accessibility_info, true
FROM places;)
    )

    # 4) create organisation_relationships table (id, subject, verb, object)
    create_table :organisation_relationships
    add_reference :organisation_relationships, :subject, null: false
    add_foreign_key :organisation_relationships, :partners, column: :subject_id
    add_column :organisation_relationships, :verb, :string, null:false
    add_reference :organisation_relationships, :object, null: false
    add_foreign_key :organisation_relationships, :partners, column: :object_id
  end


  def down

    #5)
    drop_table :organisation_relationships

    # 2)
    # Cannot delete rows. How would we idenitfy the migrated ones?

    # 1)
    change_table :partners do |t|
      t.remove :opening_times, :booking_info, :accessibility_info
    end
  end
end
