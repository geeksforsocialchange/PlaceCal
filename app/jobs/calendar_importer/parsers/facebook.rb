# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Facebook < Base

    def self.whitelist_pattern
      /^https:\/\/www.facebook.com\.*/
    end

    def page
      URI.parse(@url).path.gsub(/\A\//, '').gsub(/\/\z/, '')
    end

    def download_calendar
      @events = []

      begin
        fields = %w[name description start_time end_time updated_time place event_times]
        results = facebook_api.get_connections(page, 'events', fields: fields, since: @from.to_time.to_i, until: Calendar.import_up_to.to_time.to_i)

        loop do
          @events += results
          results = results.next_page
          break if results.blank?
        end
      rescue Koala::Facebook::APIError => e
        Rails.logger.debug e
      end

      @events
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::FacebookEvent.new(d) }
    end

    def find_by_uid(uids)
      facebook_api.get_objects(uids)
    end

    private

    def facebook_api
      Koala::Facebook::API.new(@calendar.page_access_token)
    end
  end
end
