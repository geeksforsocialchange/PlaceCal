class Event < ApplicationRecord
  acts_as_paranoid

  has_and_belongs_to_many :partners

  belongs_to :place
  belongs_to :calendar

  before_validation :set_place, if: Proc.new { |event| event.place_id.blank? }

  scope :find_by_day, -> (day) { where('dtstart >= ? AND dtstart <= ?', day.midnight, day.midnight + 1.day).order(:dtstart) }

  scope :find_by_week, -> (week) { where('dtstart >= ? AND dtstart <= ?', week.midnight, week.midnight + 6.days).order(:summary) }

  class << self
    def handle_recurring_events(uid, imports, calendar_id)
      events = where('dtstart > ? AND uid = ?', Date.today, uid)
      start_dates = imports.map(&:dtstart)
      end_dates = imports.map(&:dtend)

      events.where.not(dtstart: start_dates).or(events.where.not(dtend: end_dates )).destroy_all

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
