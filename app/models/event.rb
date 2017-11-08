# app/models/event.rb
class Event < ApplicationRecord
  has_paper_trail ignore: [:rrule, :notices]

  belongs_to :partner

  belongs_to :place, required: false
  belongs_to :address, required: false
  belongs_to :calendar

  validates :summary, :dtstart, :dtend, presence: true

  validate :require_location

  # Find by day
  scope :find_by_day, lambda { |day|
    where('dtstart >= ? AND dtstart <= ?', day.midnight, day.midnight + 1.day)
  }

  # Find by week
  scope :find_by_week, lambda { |day|
    week_start = day.beginning_of_week
    week_end = week_start + 6.days
    where('dtstart >= ? AND dtstart <= ?', week_start, week_end)
  }

  # Filter by Place
  scope :in_place, ->(place) { where(place: place) }

  # Sort by Summary or Start Time
  scope :sort_by_summary, -> { order(summary: :asc).order(:dtstart) }
  scope :sort_by_time, -> { order(dtstart: :asc).order(summary: :asc) }

  scope :without_matching_times, ->(start_times, end_times) {
    where.not(dtstart: start_times).or(where.not(dtend: end_times))
  }

  # Only events that don't repeat
  scope :one_off_events_only, -> { where(rrule: nil) }
  scope :one_off_events_first, -> { order(rrule: :desc) }

  scope :upcoming_for_date, ->(from) { where('dtstart >= ?', from.beginning_of_day)}

  def repeat_frequency
    rrule[0]['table']['frequency'].titleize if rrule
  end

  private

  def require_location
    if place_id.blank? && address_id.blank?
      errors.add(:base, "No place or address could be created or found for the event location: #{self.location}")
    end
  end
end
