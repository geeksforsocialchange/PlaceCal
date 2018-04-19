require "administrate/base_dashboard"

class EventDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    partner: Field::BelongsTo,
    place: Field::BelongsTo,
    calendar: Field::BelongsTo,
    address: Field::BelongsTo,
    id: Field::Number,
    uid: Field::String,
    summary: Field::Text,
    description: Field::Text,
    location: Field::Text,
    rrule: Field::String.with_options(searchable: false),
    notices: Field::String.with_options(searchable: false),
    is_active: Field::Boolean,
    deleted_at: Field::DateTime,
    dtstart: Field::DateTime,
    dtend: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :summary,
    :dtstart,
    :place,
    :calendar,
    :id,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :partner,
    :place,
    :calendar,
    :address,
    :id,
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :notices,
    :is_active,
    :dtstart,
    :dtend,
    :created_at,
    :updated_at,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :partner,
    :place,
    :calendar,
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :notices,
    :is_active,
    :dtstart,
    :dtend,
  ].freeze

  # Overwrite this method to customize how events are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(event)
  #   "Event ##{event.id}"
  # end
end
