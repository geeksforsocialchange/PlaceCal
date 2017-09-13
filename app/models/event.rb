# app/models/event.rb
class Event < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :partners

  belongs_to :place, required: false
  belongs_to :calendar

  # before_validation :set_place, if: Proc.new { |event| event.place_id.blank? }

  scope :find_by_day, lambda { |day|
    where('dtstart >= ? AND dtstart <= ?', day.midnight, day.midnight + 1.day)
      .order(:dtstart)
      .order(:dtend)
  }

  scope :find_by_week, lambda { |week|
    where('dtstart >= ? AND dtstart <= ?', week.midnight, week.midnight + 6.days)
      .order(:summary)
      .order(:dtstart)
  }

  scope :in_venue, ->(venue) { where(venue: venue) }

  class << self
    # UID: the root event from which we are creating events
    # Imports: 
    def handle_recurring_events(uid, imports, calendar_id)
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
