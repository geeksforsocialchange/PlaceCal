require "administrate/base_dashboard"

class PartnerDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    events: Field::HasMany,
    users: Field::HasMany,
    places: Field::HasMany,
    is_a_place: Field::Boolean,
    calendars: Field::HasMany,
    address: Field::BelongsTo,
    id: Field::Number,
    name: Field::String,
    logo: Field::String,
    public_phone: Field::String,
    public_email: Field::String,
    admin_name: Field::String,
    admin_email: Field::String,
    short_description: Field::Text,
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
    # :events,
    # :users,
    :places,
    :is_a_place,
    :calendars,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :name,
    :address,
    :short_description,
    :places,
    :is_a_place,
    :calendars,
    :logo,
    :public_phone,
    :public_email,
    :admin_name,
    :admin_email,
    :created_at,
    :updated_at,
    # :events,
    # :users,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :name,
    :address,
    :short_description,
    :logo,
    :public_phone,
    :public_email,
    :admin_name,
    :admin_email,
    :users,
    :places,
    :is_a_place,
    :calendars,
  ].freeze

  # Overwrite this method to customize how partners are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(partner)
    partner
  end
end
