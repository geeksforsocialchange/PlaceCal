# frozen_string_literal: true

class DropPlaceTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :partners_places
    drop_table :places
  end

  def down
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table 'partners_places', id: :serial, force: :cascade do |t|
      t.integer 'partner_id'
      t.integer 'place_id'
      t.index ['partner_id'], name: 'index_partners_places_on_partner_id'
      t.index ['place_id'], name: 'index_partners_places_on_place_id'
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    create_table 'places', id: :serial, force: :cascade do |t|
      t.string 'name'
      t.string 'status'
      t.string 'logo'
      t.string 'phone'
      t.jsonb 'opening_times'
      t.text 'short_description'
      t.text 'booking_info'
      t.text 'accessibility_info'
      t.integer 'address_id'
      t.string 'email'
      t.string 'url'
      t.string 'slug'
      t.timestamps
      t.index ['address_id'], name: 'index_places_on_address_id'
      t.index ['slug'], name: 'index_places_on_slug', unique: true
    end
  end
end
