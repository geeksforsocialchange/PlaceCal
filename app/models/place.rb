# app/models/place.rb
class Place < ApplicationRecord
  has_and_belongs_to_many :partners
  has_many :events
  has_many :calendars

  belongs_to :address

  validates_presence_of :name

  # Max events to show on Place page before going to a day-by-day view
  # Needs some refactoring to work
  # EVENT_VIEW_ACTIVITY_LIMIT = 20

  def to_s
    name
  end

  # How should we show the event listing on the Place page?
  def event_view
    :week
  end
end
