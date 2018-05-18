# frozen_string_literal: true

require 'administrate/base_dashboard'

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
    type: Field::Select.with_options(collection: Calendar.type.values),
    strategy: Field::Select.with_options(collection: Calendar.strategy.values),
    notices: Field::String.with_options(searchable: false),
    last_import_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    name
    partner
    place
    events
    id
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    partner
    place
    name
    source
    strategy
    type
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    partner
    place
    name
    source
    strategy
    type
  ].freeze

  # Overwrite this method to customize how calendars are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(calendar)
    calendar
  end
end
