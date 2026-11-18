# frozen_string_literal: true

module CalendarImporter::Events
  class ManchesterUniEvent < Base
    imports title: 'title', description: 'description', start_time: 'times.start', end_time: 'times.end', repeats: nil,
            location: nil, webpage: nil, online_link: nil, spaces_available: nil, status: nil, image: nil,
            source_categories: nil, source_organiser: nil

    def uid
      @event.at_xpath('./ns:id').text
    end

    def summary
      @event.at_xpath('./ns:title').text.gsub(/\A(\n)+\z/, '').strip
    end

    def description
      @event.at_xpath('./ns:description').text.gsub(/\A(\n)+\z/, '').strip
    end

    def location; end

    # The feed's local block is a bare date and time; DateTime.parse would stamp it UTC
    def dtstart
      date = @event.at_xpath('./ns:times[@type="local"] //ns:start //ns:date')
      time = @event.at_xpath('./ns:times[@type="local"] //ns:start //ns:time')
      Time.zone.parse([date, time].join(' '))
    rescue StandardError
      nil
    end

    def dtend
      date = @event.at_xpath('./ns:times[@type="local"] //ns:end //ns:date')
      time = @event.at_xpath('./ns:times[@type="local"] //ns:end //ns:time')
      Time.zone.parse([date, time].join(' '))
    rescue StandardError
      nil
    end
  end
end
