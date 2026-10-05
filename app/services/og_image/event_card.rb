# frozen_string_literal: true

module OgImage
  class EventCard < BaseCard
    def initialize(event)
      super()
      @event = event
    end

    private

    attr_reader :event

    def label
      t('labels.event')
    end

    def title
      event.summary
    end

    def accent
      ACCENTS[:event]
    end

    def rows
      [
        [:clock, time],
        [:calendar, I18n.l(event.dtstart, format: :og_date)],
        [:map_pin, venue],
        [:users, event.organiser&.name]
      ]
    end

    def time
      start = format_time(event.dtstart)
      return start unless event.dtend

      "#{start} – #{format_time(event.dtend)}"
    end

    def format_time(datetime)
      I18n.l(datetime, format: :og_time).strip
    end

    def venue
      event.partner_at_location&.name.presence || event.location
    end
  end
end
