class CreateInitialTables < ActiveRecord::Migration[5.0]
  def change
    create_table :addresses do |t|
      t.string :street_address
      t.string :street_address2
      t.string :street_address3
      t.string :city
      t.string :postcode
      t.string :country_code, default: 'UK'

      #for geocoder
      t.float :latitude
      t.float :longitude
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
