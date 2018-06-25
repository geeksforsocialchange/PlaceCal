module Parsers
  class Zarts < Xml

    def events
      @events = []
      download_calendar.css('show').each do |show|
        @events << Events::ZartsEvent.new(show)
      end

      @events
    end

  end
end
