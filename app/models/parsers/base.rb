module Parsers
  class Base

    Output = Struct.new(:events, :checksum)

    def initialize(calendar, url, options={})
      @calendar = calendar
      @url = url
      @from = options.delete(:from)
      @to = options.delete(:to)
    end

	  # Takes a calendar feed and imports it
    # Returns array of events
    #
    def calendar_to_events(skip_checksum=false)
      data   = download_calendar
      checksum = digest(data)

      if skip_checksum || (@calendar.last_checksum == checksum)
        return []
      end

      Output.new(import_events_from(data), checksum)
    end

    def download_calendar
      #raise NotImplemented, 'This method must be implemented by the subclass'
    end

    def import_events_from(data)
      #raise NotImplemented, 'This method must be implemented by the subclass'
    end

    def digest(data)
      Digest::MD5.hexdigest(data)
    end
  end
end
