# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength

class CreateInitialTables < ActiveRecord::Migration[5.0]
  def change
    create_table 'neighbourhoods', force: :cascade do |t|
      t.string 'name'
      t.string 'name_abbr'
      t.string 'ancestry'
      t.string 'unit', default: 'ward'
      t.string 'unit_code_key', default: 'WD19CD'
      t.string 'unit_code_value'
      t.string 'unit_name'
      t.string 'parent_name'
      t.index ['ancestry'], name: 'index_neighbourhoods_on_ancestry'
    end

    create_table 'sites_neighbourhoods', force: :cascade do |t|
      t.integer 'neighbourhood_id'
      t.integer 'site_id'
      t.string 'relation_type'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
    end

    create_table 'tags', force: :cascade do |t|
      t.string 'name'
      t.string 'slug'
      t.text 'description'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.boolean 'system_tag', default: false
      t.string 'type'
    end

    create_table 'tags_users', force: :cascade do |t|
      t.bigint 'tag_id', null: false
      t.bigint 'user_id', null: false
      t.index %w[tag_id user_id], name: 'index_tags_users_on_tag_id_and_user_id'
      t.index %w[user_id tag_id], name: 'index_tags_users_on_user_id_and_tag_id'
    end

    create_table 'partner_tags', force: :cascade do |t|
      t.bigint 'partner_id', null: false
      t.bigint 'tag_id', null: false
      t.index %w[partner_id tag_id], name: 'index_partner_tags_on_partner_id_and_tag_id'
      t.index %w[tag_id partner_id], name: 'index_partner_tags_on_tag_id_and_partner_id'
    end

    create_table :addresses do |t|
      t.string :street_address
      t.string :street_address2
      t.string :street_address3
      t.string :city
      t.string :postcode
      t.string :country_code, default: 'UK'

      # for geocoder
      t.float :latitude
      t.float :longitude

      t.bigint 'neighbourhood_id'
      t.index ['neighbourhood_id'], name: 'index_addresses_on_neighbourhood_id'
    end

    create_table :partners do |t|
      t.string :name
      t.string :logo
      t.string :public_phone
      t.string :public_email
      t.string :admin_name
      t.string :admin_email
      t.text :short_description
      t.references :address, foreign_key: true

      t.timestamps null: false
    end

    create_table :places do |t|
      t.string :name
      t.string :status
      t.string :logo
      t.string :phone
      t.jsonb :opening_times
      t.text :short_description
      t.text :booking_info
      t.text :accessibility_info

      t.references :address, foreign_key: true

      t.timestamps null: false
    end

    create_table :calendars do |t|
      t.string :name
      t.string :source
      t.string :type
      t.jsonb :notices
      t.timestamp :last_import_at
      t.references :partner, foreign_key: true
      t.references :place, foreign_key: true

      t.timestamps null: false
    end

    create_table :events do |t|
      t.references :place, foreign_key: true
      t.references :calendar, foreign_key: true
      t.string :uid
      t.text :summary
      t.text :description
      t.text :location
      t.jsonb :rrule
      t.jsonb :notices
      t.boolean :is_active, default: true, null: false
      t.datetime :deleted_at, index: true
      t.datetime :dtstart
      t.datetime :dtend

      t.timestamps null: false
    end

    create_table :partners_places do |t|
      t.references :partner, foreign_key: true
      t.references :place, foreign_key: true
    end

    create_table :events_partners do |t|
      t.references :event, foreign_key: true
      t.references :partner, foreign_key: true
    end

    create_table :partners_users do |t|
      t.references :partner, foreign_key: true
      t.references :user, foreign_key: true
    end
  end
end

# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
