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

ActiveRecord::Schema[8.1].define(version: 2026_02_12_204459) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "city"
    t.string "country_code", default: "UK", null: false
    t.float "latitude"
    t.float "longitude"
    t.bigint "neighbourhood_id"
    t.string "postcode", null: false
    t.string "street_address", null: false
    t.string "street_address2"
    t.string "street_address3"
    t.index ["neighbourhood_id"], name: "index_addresses_on_neighbourhood_id"
  end

  create_table "article_partners", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "partner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "partner_id"], name: "index_article_partners_on_article_id_and_partner_id", unique: true
    t.index ["partner_id"], name: "index_article_partners_on_partner_id"
  end

  create_table "article_tags", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "tag_id"], name: "index_article_tags_article_id_tag_id", unique: true
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "articles", force: :cascade do |t|
    t.string "article_image"
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.string "body_html"
    t.datetime "created_at", null: false
    t.boolean "is_draft", default: true, null: false
    t.date "published_at"
    t.string "slug"
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "calendars", force: :cascade do |t|
    t.string "api_token"
    t.string "calendar_state", default: "idle"
    t.datetime "checksum_updated_at"
    t.datetime "created_at", precision: nil, null: false
    t.text "critical_error"
    t.string "importer_mode", default: "auto"
    t.string "importer_used"
    t.boolean "is_working", default: true, null: false
    t.string "last_checksum"
    t.datetime "last_import_at", precision: nil
    t.string "name", null: false
    t.integer "notice_count"
    t.jsonb "notices"
    t.bigint "partner_id", null: false
    t.bigint "place_id"
    t.string "public_contact_email"
    t.string "public_contact_name"
    t.string "public_contact_phone"
    t.string "source", null: false
    t.string "strategy"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["calendar_state"], name: "index_calendars_on_calendar_state"
    t.index ["partner_id"], name: "index_calendars_on_partner_id"
    t.index ["place_id"], name: "index_calendars_on_place_id"
    t.index ["source"], name: "index_calendars_source", unique: true
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "image"
    t.string "name"
    t.string "route"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "collections_events", id: false, force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "event_id", null: false
    t.index ["collection_id", "event_id"], name: "index_collections_events_on_collection_id_and_event_id"
    t.index ["event_id", "collection_id"], name: "index_collections_events_on_event_id_and_collection_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at", precision: nil
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "address_id"
    t.string "are_spaces_available"
    t.bigint "calendar_id"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "description_html"
    t.datetime "dtend", precision: nil
    t.datetime "dtstart", precision: nil, null: false
    t.text "footer"
    t.boolean "is_active", default: true, null: false
    t.jsonb "notices"
    t.bigint "online_address_id"
    t.bigint "partner_id", null: false
    t.bigint "place_id"
    t.string "publisher_url"
    t.text "raw_location_from_source"
    t.jsonb "rrule"
    t.text "summary", null: false
    t.string "summary_html"
    t.string "uid"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["address_id"], name: "index_events_address_id"
    t.index ["calendar_id", "dtstart"], name: "index_events_calendar_id_dtstart"
    t.index ["dtstart"], name: "index_events_dtstart"
    t.index ["online_address_id"], name: "index_events_on_online_address_id"
    t.index ["partner_id", "dtstart"], name: "index_events_on_partner_id_and_dtstart"
    t.index ["place_id"], name: "index_events_on_place_id"
    t.index ["uid"], name: "index_events_uid"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "neighbourhoods", force: :cascade do |t|
    t.string "ancestry"
    t.integer "level"
    t.string "name"
    t.string "name_abbr"
    t.string "parent_name"
    t.integer "partners_count", default: 0, null: false
    t.datetime "release_date", precision: nil
    t.string "unit", default: "ward"
    t.string "unit_code_key", default: "WD19CD"
    t.string "unit_code_value"
    t.string "unit_name"
    t.index ["ancestry"], name: "index_neighbourhoods_on_ancestry"
    t.index ["level"], name: "index_neighbourhoods_on_level"
    t.index ["partners_count"], name: "index_neighbourhoods_on_partners_count"
  end

  create_table "neighbourhoods_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "neighbourhood_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["neighbourhood_id", "user_id"], name: "index_neighbourhoods_users_neighbourhood_id_user_id", unique: true
    t.index ["user_id"], name: "index_neighbourhoods_users_on_user_id"
  end

  create_table "online_addresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "link_type"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "organisation_relationships", force: :cascade do |t|
    t.bigint "partner_object_id", null: false
    t.bigint "partner_subject_id", null: false
    t.string "verb", null: false
    t.index ["partner_object_id"], name: "index_organisation_relationships_on_partner_object_id"
    t.index ["partner_subject_id", "verb", "partner_object_id"], name: "unique_organisation_relationship_row", unique: true
  end

  create_table "partner_tags", force: :cascade do |t|
    t.bigint "partner_id", null: false
    t.bigint "tag_id", null: false
    t.index ["partner_id", "tag_id"], name: "index_partner_tags_partner_id_tag_id", unique: true
    t.index ["tag_id", "partner_id"], name: "index_partner_tags_on_tag_id_and_partner_id"
  end

  create_table "partners", force: :cascade do |t|
    t.text "accessibility_info"
    t.string "accessibility_info_html"
    t.bigint "address_id"
    t.string "admin_email"
    t.string "admin_name"
    t.text "booking_info"
    t.string "calendar_email"
    t.string "calendar_name"
    t.string "calendar_phone"
    t.boolean "can_be_assigned_events", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "description_html"
    t.string "facebook_link"
    t.boolean "hidden", default: false, null: false
    t.integer "hidden_blame_id"
    t.text "hidden_reason"
    t.string "hidden_reason_html"
    t.string "image"
    t.string "instagram_handle"
    t.boolean "is_a_place", default: false, null: false
    t.string "name", null: false
    t.jsonb "opening_times"
    t.string "partner_email"
    t.string "partner_name"
    t.string "partner_phone"
    t.string "public_email"
    t.string "public_name"
    t.string "public_phone"
    t.string "slug"
    t.string "summary"
    t.string "summary_html"
    t.string "twitter_handle"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index "lower((name)::text)", name: "index_partners_lower_name_", unique: true
    t.index ["address_id"], name: "index_partners_on_address_id"
    t.index ["hidden"], name: "index_partners_hidden"
    t.index ["slug"], name: "index_partners_on_slug", unique: true
  end

  create_table "partners_users", id: :serial, force: :cascade do |t|
    t.integer "partner_id"
    t.integer "user_id"
    t.index ["partner_id", "user_id"], name: "index_partners_users_partner_id_user_id", unique: true
    t.index ["user_id", "partner_id"], name: "index_partners_users_user_id_partner_id"
  end

  create_table "seed_migration_data_migrations", id: :serial, force: :cascade do |t|
    t.datetime "migrated_on", precision: nil
    t.integer "runtime"
    t.string "version"
  end

  create_table "service_areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "neighbourhood_id", null: false
    t.bigint "partner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["neighbourhood_id", "partner_id"], name: "index_service_areas_on_neighbourhood_id_and_partner_id", unique: true
    t.index ["partner_id"], name: "index_service_areas_on_partner_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "badge_zoom_level"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "description_html"
    t.integer "events_count", default: 0, null: false
    t.string "footer_logo"
    t.string "hero_alttext"
    t.string "hero_image"
    t.string "hero_image_credit"
    t.string "hero_text"
    t.boolean "is_published", default: false, null: false
    t.string "logo"
    t.string "name", null: false
    t.integer "partners_count", default: 0, null: false
    t.string "place_name"
    t.bigint "site_admin_id"
    t.string "slug", null: false
    t.string "tagline"
    t.string "theme"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url", null: false
    t.index ["events_count"], name: "index_sites_on_events_count"
    t.index ["is_published"], name: "index_sites_is_published"
    t.index ["partners_count"], name: "index_sites_on_partners_count"
    t.index ["slug"], name: "index_sites_slug", unique: true
    t.index ["url"], name: "index_sites_url"
  end

  create_table "sites_neighbourhoods", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.bigint "neighbourhood_id", null: false
    t.string "relation_type"
    t.bigint "site_id", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["neighbourhood_id", "site_id"], name: "index_sites_neighbourhoods_neighbourhood_id_site_id", unique: true
    t.index ["site_id"], name: "index_sites_neighbourhoods_site_id"
  end

  create_table "sites_supporters", id: false, force: :cascade do |t|
    t.bigint "site_id", null: false
    t.bigint "supporter_id", null: false
    t.index ["site_id", "supporter_id"], name: "index_sites_supporters_site_id_supporter_id", unique: true
    t.index ["supporter_id", "site_id"], name: "index_sites_supporters_on_supporter_id_and_site_id"
  end

  create_table "sites_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "site_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "tag_id"], name: "index_sites_tags_on_site_id_and_tag_id", unique: true
    t.index ["tag_id"], name: "index_sites_tags_on_tag_id"
  end

  create_table "supporters", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.boolean "is_global", default: false, null: false
    t.string "logo"
    t.string "name", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.integer "weight"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.boolean "system_tag", default: false, null: false
    t.string "type", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name", "type"], name: "index_tags_name_type", unique: true
    t.index ["slug", "type"], name: "index_tags_slug_type", unique: true
  end

  create_table "tags_users", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "user_id", null: false
    t.index ["tag_id", "user_id"], name: "index_tags_users_tag_id_user_id", unique: true
    t.index ["user_id", "tag_id"], name: "index_tags_users_on_user_id_and_tag_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "access_token"
    t.string "access_token_expires_at"
    t.string "avatar"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "first_name"
    t.datetime "invitation_accepted_at", precision: nil
    t.datetime "invitation_created_at", precision: nil
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at", precision: nil
    t.string "invitation_token"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.string "phone"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.string "role", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "addresses", "neighbourhoods"
  add_foreign_key "article_partners", "articles"
  add_foreign_key "article_partners", "partners"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "articles", "users", column: "author_id"
  add_foreign_key "calendars", "partners"
  add_foreign_key "calendars", "partners", column: "place_id"
  add_foreign_key "events", "addresses"
  add_foreign_key "events", "calendars"
  add_foreign_key "events", "online_addresses"
  add_foreign_key "events", "partners"
  add_foreign_key "events", "partners", column: "place_id"
  add_foreign_key "neighbourhoods_users", "neighbourhoods"
  add_foreign_key "neighbourhoods_users", "users"
  add_foreign_key "organisation_relationships", "partners", column: "partner_object_id"
  add_foreign_key "organisation_relationships", "partners", column: "partner_subject_id"
  add_foreign_key "partner_tags", "partners"
  add_foreign_key "partner_tags", "tags"
  add_foreign_key "partners", "addresses"
  add_foreign_key "partners_users", "partners"
  add_foreign_key "partners_users", "users"
  add_foreign_key "service_areas", "neighbourhoods"
  add_foreign_key "service_areas", "partners"
  add_foreign_key "sites", "users", column: "site_admin_id"
  add_foreign_key "sites_neighbourhoods", "neighbourhoods"
  add_foreign_key "sites_neighbourhoods", "sites"
  add_foreign_key "sites_supporters", "sites"
  add_foreign_key "sites_supporters", "supporters"
  add_foreign_key "sites_tags", "sites"
  add_foreign_key "sites_tags", "tags"
  add_foreign_key "tags_users", "tags"
  add_foreign_key "tags_users", "users"
end
