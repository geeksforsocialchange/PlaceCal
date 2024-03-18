# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_03_14_121308) do
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
    t.bigint "neighbourhood_id"
    t.index ["neighbourhood_id"], name: "index_addresses_on_neighbourhood_id"
  end

  create_table "article_partners", force: :cascade do |t|
    t.bigint "article_id"
    t.bigint "partner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "partner_id"], name: "index_article_partners_on_article_id_and_partner_id", unique: true
    t.index ["article_id"], name: "index_article_partners_on_article_id"
    t.index ["partner_id"], name: "index_article_partners_on_partner_id"
  end

  create_table "article_tags", force: :cascade do |t|
    t.bigint "article_id"
    t.bigint "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.text "title"
    t.text "body"
    t.date "published_at"
    t.boolean "is_draft", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "author_id"
    t.string "article_image"
    t.string "slug"
    t.string "body_html"
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "calendars", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "source"
    t.jsonb "notices"
    t.datetime "last_import_at", precision: nil
    t.integer "partner_id"
    t.integer "place_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "strategy"
    t.string "last_checksum"
    t.text "critical_error"
    t.string "page_access_token"
    t.boolean "is_working", default: true, null: false
    t.string "public_contact_name"
    t.string "public_contact_email"
    t.string "public_contact_phone"
    t.integer "notice_count"
    t.string "calendar_state", default: "idle"
    t.string "importer_mode", default: "auto"
    t.string "importer_used"
    t.index ["partner_id"], name: "index_calendars_on_partner_id"
    t.index ["place_id"], name: "index_calendars_on_place_id"
  end

  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image"
    t.string "route"
  end

  create_table "collections_events", id: false, force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "event_id", null: false
    t.index ["collection_id", "event_id"], name: "index_collections_events_on_collection_id_and_event_id"
    t.index ["event_id", "collection_id"], name: "index_collections_events_on_event_id_and_collection_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "place_id"
    t.integer "calendar_id"
    t.string "uid"
    t.text "summary"
    t.text "description"
    t.text "raw_location_from_source"
    t.jsonb "rrule"
    t.jsonb "notices"
    t.boolean "is_active", default: true, null: false
    t.datetime "dtstart", precision: nil
    t.datetime "dtend", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "partner_id"
    t.integer "address_id"
    t.string "are_spaces_available"
    t.text "footer"
    t.string "publisher_url"
    t.bigint "online_address_id"
    t.string "description_html"
    t.string "summary_html"
    t.index ["calendar_id"], name: "index_events_on_calendar_id"
    t.index ["online_address_id"], name: "index_events_on_online_address_id"
    t.index ["place_id"], name: "index_events_on_place_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "neighbourhoods", force: :cascade do |t|
    t.string "name"
    t.string "name_abbr"
    t.string "ancestry"
    t.string "unit", default: "ward"
    t.string "unit_code_key", default: "WD19CD"
    t.string "unit_code_value"
    t.string "unit_name"
    t.string "parent_name"
    t.datetime "release_date", precision: nil
    t.index ["ancestry"], name: "index_neighbourhoods_on_ancestry"
  end

  create_table "neighbourhoods_users", force: :cascade do |t|
    t.bigint "neighbourhood_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["neighbourhood_id"], name: "index_neighbourhoods_users_on_neighbourhood_id"
    t.index ["user_id"], name: "index_neighbourhoods_users_on_user_id"
  end

  create_table "online_addresses", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link_type"
  end

  create_table "organisation_relationships", force: :cascade do |t|
    t.bigint "partner_subject_id", null: false
    t.string "verb", null: false
    t.bigint "partner_object_id", null: false
    t.index ["partner_object_id"], name: "index_organisation_relationships_on_partner_object_id"
    t.index ["partner_subject_id", "verb", "partner_object_id"], name: "unique_organisation_relationship_row", unique: true
    t.index ["partner_subject_id"], name: "index_organisation_relationships_on_partner_subject_id"
  end

  create_table "partner_tags", force: :cascade do |t|
    t.bigint "partner_id", null: false
    t.bigint "tag_id", null: false
    t.index ["partner_id", "tag_id"], name: "index_partner_tags_on_partner_id_and_tag_id"
    t.index ["tag_id", "partner_id"], name: "index_partner_tags_on_tag_id_and_partner_id"
  end

  create_table "partners", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "public_phone"
    t.string "public_email"
    t.string "admin_name"
    t.string "admin_email"
    t.integer "address_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_a_place"
    t.string "slug"
    t.string "partner_email"
    t.string "partner_name"
    t.string "partner_phone"
    t.string "calendar_email"
    t.string "calendar_phone"
    t.string "calendar_name"
    t.string "public_name"
    t.string "url"
    t.jsonb "opening_times"
    t.text "booking_info"
    t.text "accessibility_info"
    t.string "twitter_handle"
    t.string "facebook_link"
    t.string "summary"
    t.text "description"
    t.string "description_html"
    t.string "summary_html"
    t.string "accessibility_info_html"
    t.boolean "hidden", default: false
    t.text "hidden_reason"
    t.integer "hidden_blame_id"
    t.string "hidden_reason_html"
    t.string "instagram_handle"
    t.index ["address_id"], name: "index_partners_on_address_id"
    t.index ["slug"], name: "index_partners_on_slug", unique: true
  end

  create_table "partners_users", id: :serial, force: :cascade do |t|
    t.integer "partner_id"
    t.integer "user_id"
    t.index ["partner_id"], name: "index_partners_users_on_partner_id"
    t.index ["user_id"], name: "index_partners_users_on_user_id"
  end

  create_table "seed_migration_data_migrations", id: :serial, force: :cascade do |t|
    t.string "version"
    t.integer "runtime"
    t.datetime "migrated_on", precision: nil
  end

  create_table "service_areas", force: :cascade do |t|
    t.bigint "neighbourhood_id"
    t.bigint "partner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["neighbourhood_id", "partner_id"], name: "index_service_areas_on_neighbourhood_id_and_partner_id", unique: true
    t.index ["neighbourhood_id"], name: "index_service_areas_on_neighbourhood_id"
    t.index ["partner_id"], name: "index_service_areas_on_partner_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "url"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "site_admin_id"
    t.string "logo"
    t.string "hero_image"
    t.string "hero_image_credit"
    t.string "footer_logo"
    t.string "tagline", default: "The Community Calendar"
    t.string "place_name"
    t.string "theme"
    t.boolean "is_published", default: false
    t.string "badge_zoom_level"
    t.string "description_html"
    t.string "hero_text"
    t.index ["site_admin_id"], name: "index_sites_on_site_admin_id"
  end

  create_table "sites_neighbourhoods", force: :cascade do |t|
    t.integer "neighbourhood_id"
    t.integer "site_id"
    t.string "relation_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sites_supporters", id: false, force: :cascade do |t|
    t.bigint "site_id", null: false
    t.bigint "supporter_id", null: false
    t.index ["site_id", "supporter_id"], name: "index_sites_supporters_on_site_id_and_supporter_id"
    t.index ["supporter_id", "site_id"], name: "index_sites_supporters_on_supporter_id_and_site_id"
  end

  create_table "sites_tags", force: :cascade do |t|
    t.bigint "site_id"
    t.bigint "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "tag_id"], name: "index_sites_tags_on_site_id_and_tag_id", unique: true
    t.index ["site_id"], name: "index_sites_tags_on_site_id"
    t.index ["tag_id"], name: "index_sites_tags_on_tag_id"
  end

  create_table "supporters", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "logo"
    t.string "description"
    t.integer "weight"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_global", default: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "system_tag", default: false
    t.string "type"
  end

  create_table "tags_users", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "user_id", null: false
    t.index ["tag_id", "user_id"], name: "index_tags_users_on_tag_id_and_user_id"
    t.index ["user_id", "tag_id"], name: "index_tags_users_on_user_id_and_tag_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.string "phone"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "access_token"
    t.string "access_token_expires_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.string "avatar"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "addresses", "neighbourhoods"
  add_foreign_key "articles", "users", column: "author_id"
  add_foreign_key "calendars", "partners"
  add_foreign_key "calendars", "partners", column: "place_id"
  add_foreign_key "events", "addresses"
  add_foreign_key "events", "calendars"
  add_foreign_key "events", "online_addresses"
  add_foreign_key "events", "partners"
  add_foreign_key "events", "partners", column: "place_id"
  add_foreign_key "organisation_relationships", "partners", column: "partner_object_id"
  add_foreign_key "organisation_relationships", "partners", column: "partner_subject_id"
  add_foreign_key "partners", "addresses"
  add_foreign_key "partners_users", "partners"
  add_foreign_key "partners_users", "users"
  add_foreign_key "service_areas", "neighbourhoods"
  add_foreign_key "service_areas", "partners"
  add_foreign_key "sites", "users", column: "site_admin_id"
  add_foreign_key "sites_tags", "sites"
  add_foreign_key "sites_tags", "tags"
end
