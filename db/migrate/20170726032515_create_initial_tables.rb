class CreateInitialTables < ActiveRecord::Migration[5.0]
  def change
    create_table :partners do |t|
      t.string :name
      t.text :description
      t.string :region
      t.string :logo
      t.text :hire_info

      t.timestamps null: false
    end

    create_table :places do |t|
      t.string :name
      t.string :status
      t.string :street_address
      t.string :street_address2
      t.string :street_address3
      t.string :city
      t.string :postcode
      t.jsonb :hours
      t.text :accessibility_info

      #for geocoder
      t.float :latitude
      t.float :longitude

      t.timestamps null: false
    end

    create_table :events do |t|
      t.references :place, foreign_key: true
      t.string :uid
      t.datetime :dtstart
      t.datetime :dtend
      t.text :summary
      t.text :description
      t.text :location
      t.text :rrule
      t.boolean :is_active, default: false, null: false

      t.timestamps null: false
    end

    create_table :calendars do |t|
      t.references :partner, foreign_key: true
      t.string :name
      t.string :feed_url
      t.string :region
      t.string :type
      t.integer :default_place_id

      t.timestamps null: false
    end

    create_table :partners_places do |t|
      t.references :partners, foreign_key: true
      t.references :places, foreign_key: true
    end

    create_table :events_partners do |t|
      t.references :events, foreign_key: true
      t.references :partners, foreign_key: true
    end

    create_table :partners_users do |t|
      t.references :partner, foreign_key: true
      t.references :user, foreign_key: true
    end
  end
end
