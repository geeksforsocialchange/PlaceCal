# app/models/event.rb
class Event < ApplicationRecord
  acts_as_paranoid
  has_paper_trail ignore: [:rrule, :notices]

  belongs_to :partner

  belongs_to :place, required: false
  belongs_to :address, required: false
  belongs_to :calendar

  validates :summary, :dtstart, :dtend, presence: true

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

  scope :upcoming_for_date, ->(from) { where("dtstart >= ?", from.beginning_of_day) }

end
