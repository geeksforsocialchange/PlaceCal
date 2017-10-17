require "administrate/base_dashboard"

class PlaceDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    partners: Field::HasMany,
    events: Field::HasMany,
    calendars: Field::HasMany,
    address: Field::BelongsTo,
    id: Field::Number,
    name: Field::String,
    status: Field::String,
    logo: Field::String,
    phone: Field::String,
    email: Field::String,
    url: Field::String,
    opening_times: Field::String.with_options(searchable: false),
    short_description: Field::Text,
    booking_info: Field::Text,
    accessibility_info: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :name,
    :partners,
    :events,
    :calendars,
    :address,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :partners,
    # :events,
    :calendars,
    :address,
    :status,
    :logo,
    :phone,
    :email,
    :url,
    :opening_times,
    :short_description,
    :booking_info,
    :accessibility_info,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :short_description,
    # :events,
    :address,
    :status,
    :phone,
    :email,
    :url,
    :opening_times,
    :partners,
    :calendars,
    :logo,
    # :booking_info,
    # :accessibility_info,
  ].freeze

  # Overwrite this method to customize how places are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(place)
    place
  end
end
