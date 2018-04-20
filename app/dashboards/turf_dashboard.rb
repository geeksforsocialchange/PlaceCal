require "administrate/base_dashboard"

class TurfDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    users: Field::HasMany,
    partners: Field::HasMany,
    places: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    turf_type: Field::String,
    description: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :users,
    :partners,
    :places,
    :id,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :users,
    :partners,
    :places,
    :id,
    :name,
    :slug,
    :turf_type,
    :description,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :users,
    :partners,
    :places,
    :name,
    :slug,
    :turf_type,
    :description,
  ].freeze

  # Overwrite this method to customize how turves are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(turf)
  #   "Turf ##{turf.id}"
  # end
end
