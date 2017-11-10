class Collection < ApplicationRecord
  has_and_belongs_to_many :events

  # Sort associated events by start date
  def sorted_events
    events.order(:dtstart).includes(:place)
  end

  # The first date in this time sequence
  def start_date
    sorted_events&.first&.dtstart
  end
end
