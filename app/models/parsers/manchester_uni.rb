module Parsers
  class ManchesterUni < Xml

    def events
      @events = []

      download_calendar.xpath('//ns:event').each do |event|
        ap event
        @events << Events::ManchesterUniEvent.new(event)
      end

      @events
    end

  end
end
