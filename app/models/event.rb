# app/models/event.rb
class Event < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :partners

  belongs_to :place, required: false
  belongs_to :calendar

  before_validation :set_place_and_partner

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

  def set_place_and_partner
    return if place_id.present? || partner_id.present?

    self.place_id   = calendar.place_id
    self.partner_id = calendar.partner_id
  end
end
