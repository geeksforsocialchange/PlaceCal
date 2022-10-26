# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Squarespace  < Base
    # These constants are only used for the frontend interface
    NAME = 'Squarspace'
    KEY = 'squarespace'
    DOMAINS = %w[squarespace.com].freeze

    def self.whitelist_pattern
      %r{^https://.*\.squarespace\.com/[^/]*/?$}
    end

    def download_calendar
      json_url = @url + '?format=json'
      response = HTTParty.get(json_url)
      return [] unless response.success?

      json = safely_parse_json response.body, []
    end

    def import_events_from(data)
      unless data['upcoming']
        puts "If you are seeing this it is likely that you are using the wrong URL"
        puts "or squarespace have changed their API"
        return [] 
      end
      data['upcoming'].map { |d| 
        d['url'] = data['website']['baseUrl'] + data['collection']['fullUrl']
        d
      }
      .map { |d| CalendarImporter::Events::SquarespaceEvent.new(d) }
    end
  end
end
