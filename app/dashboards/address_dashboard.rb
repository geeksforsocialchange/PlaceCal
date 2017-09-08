require "administrate/base_dashboard"

class AddressDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    street_address: Field::String,
    street_address2: Field::String,
    street_address3: Field::String,
    city: Field::String,
    postcode: Field::String,
    country_code: Field::String,
    latitude: Field::Number.with_options(decimals: 2),
    longitude: Field::Number.with_options(decimals: 2),
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :street_address,
    :street_address2,
    :street_address3,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :street_address,
    :street_address2,
    :street_address3,
    :city,
    :postcode,
    :country_code,
    :latitude,
    :longitude,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :street_address,
    :street_address2,
    :street_address3,
    :city,
    :postcode,
    :country_code,
  ].freeze

  # Overwrite this method to customize how addresses are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(address)
    address
  end
end
