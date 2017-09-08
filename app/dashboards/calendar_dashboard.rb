require "administrate/base_dashboard"

class CalendarDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    partner: Field::BelongsTo,
    place: Field::BelongsTo,
    events: Field::HasMany,
    id: Field::Number,
    name: Field::String,
    source: Field::String,
    type: Field::String,
    strategy: Field::String,
    notices: Field::String.with_options(searchable: false),
    last_import_at: Field::DateTime,
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
    :partner,
    :place,
    :events,
    :id,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :partner,
    :place,
    :events,
    :id,
    :name,
    :source,
    :strategy,
    :type,
    :notices,
    :last_import_at,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :partner,
    :place,
    :name,
    :source,
    :strategy,
    :type,
  ].freeze

  # Overwrite this method to customize how calendars are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(calendar)
    calendar
  end
end
