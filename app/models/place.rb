# app/models/place.rb
class Place < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :partners
  has_and_belongs_to_many :turfs
  has_many :events
  has_many :calendars

  belongs_to :address, inverse_of: :places
  accepts_nested_attributes_for :address, reject_if: lambda { |c| c[:postcode].blank? && c[:street_address].blank?}
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :turf_ids

  # Max events to show on Place page before going to a day-by-day view
  # Needs some refactoring to work
  # EVENT_VIEW_AC TIVITY_LIMIT = 20

  def to_s
    name
  end

  def permalink
    "https://placecal.org/places/#{id}"
  end

  # How should we show the event listing on the Place page?
  def event_view
    :week
  end
end
