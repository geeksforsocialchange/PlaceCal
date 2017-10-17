# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171017160904) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "street_address"
    t.string "street_address2"
    t.string "street_address3"
    t.string "city"
    t.string "postcode"
    t.string "country_code", default: "UK"
    t.float "latitude"
    t.float "longitude"
  end

  create_table "calendars", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "source"
    t.string "type"
    t.jsonb "notices"
    t.datetime "last_import_at"
    t.integer "partner_id"
    t.integer "place_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "strategy"
    t.integer "address_id"
    t.index ["partner_id"], name: "index_calendars_on_partner_id"
    t.index ["place_id"], name: "index_calendars_on_place_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "place_id"
    t.integer "calendar_id"
    t.string "uid"
    t.text "summary"
    t.text "description"
    t.text "location"
    t.jsonb "rrule"
    t.jsonb "notices"
    t.boolean "is_active", default: true, null: false
    t.datetime "deleted_at"
    t.datetime "dtstart"
    t.datetime "dtend"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "partner_id"
    t.integer "address_id"
    t.index ["calendar_id"], name: "index_events_on_calendar_id"
    t.index ["deleted_at"], name: "index_events_on_deleted_at"
    t.index ["place_id"], name: "index_events_on_place_id"
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.string "public_phone"
    t.string "public_email"
    t.string "admin_name"
    t.string "admin_email"
    t.text "short_description"
    t.integer "address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_partners_on_address_id"
  end

  create_table "partners_places", id: :serial, force: :cascade do |t|
    t.integer "partner_id"
    t.integer "place_id"
    t.index ["partner_id"], name: "index_partners_places_on_partner_id"
    t.index ["place_id"], name: "index_partners_places_on_place_id"
  end

  create_table "partners_users", id: :serial, force: :cascade do |t|
    t.integer "partner_id"
    t.integer "user_id"
    t.index ["partner_id"], name: "index_partners_users_on_partner_id"
    t.index ["user_id"], name: "index_partners_users_on_user_id"
  end

  create_table "places", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "logo"
    t.string "phone"
    t.jsonb "opening_times"
    t.text "short_description"
    t.text "booking_info"
    t.text "accessibility_info"
    t.integer "address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "url"
    t.index ["address_id"], name: "index_places_on_address_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "phone"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "calendars", "addresses"
  add_foreign_key "calendars", "partners"
  add_foreign_key "calendars", "places"
  add_foreign_key "events", "addresses"
  add_foreign_key "events", "calendars"
  add_foreign_key "events", "partners"
  add_foreign_key "events", "places"
  add_foreign_key "partners", "addresses"
  add_foreign_key "partners_places", "partners"
  add_foreign_key "partners_places", "places"
  add_foreign_key "partners_users", "partners"
  add_foreign_key "partners_users", "users"
  add_foreign_key "places", "addresses"
end
