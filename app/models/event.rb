# app/models/event.rb
class Event < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :partners

  belongs_to :place, required: false
  belongs_to :calendar

  # before_validation :set_place, if: Proc.new { |event| event.place_id.blank? }

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

  class << self
    # UID: the root event from which we are creating events
    def handle_recurring_events(uid, imports, calendar_id) # rubocop:disable all
      events = where('uid = ?', uid)
      start_dates = imports.map(&:dtstart)
      end_dates = imports.map(&:dtend)

      events.where.not(dtstart: start_dates)
            .or(events.where.not(dtend: end_dates))
            .destroy_all

      imports.each do |import|
        attributes = import.attributes.merge(calendar_id: calendar_id)

        if event = self.find_by(uid: uid, dtstart: import.dtstart, dtend: import.dtend)
          event.update_attributes!(attributes.except(:uid))
        else
          self.create!(attributes)
        end
      end
    end
  end

  private

  def set_place
    Rails.logger.debug calendar.inspect
    self.place_id = calendar.place_id
  end
end
