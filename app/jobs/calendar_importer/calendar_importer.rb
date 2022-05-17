# frozen_string_literal: true

# CalendarImporter - detect calendar url and use appropriate adapter
class CalendarImporter::CalendarImporter
  class UnsupportedFeed < StandardError; end
  class InaccessibleFeed < StandardError; end

  PARSERS = [
    CalendarImporter::Parsers::ManchesterUni,
    CalendarImporter::Parsers::Ticketsolve,
    CalendarImporter::Parsers::Facebook,
    CalendarImporter::Parsers::Ics,
    CalendarImporter::Parsers::Eventbrite,
    CalendarImporter::Parsers::Meetup
  ].freeze

  def initialize(calendar)
    @calendar = calendar

    validate_feed!
  end

  def parser
    @parser ||=
      if @calendar.importer_mode == 'auto'
        PARSERS.find { |parser| parser.handles_url?(@calendar.source) }
      else
        PARSERS.find { |parser| parser::KEY == @calendar.importer_mode }
      end
  end

  private

  def validate_feed!
    raise InaccessibleFeed, "The URL could not be reached for calendar #{@calendar.name}" unless is_url_accessible?
    raise UnsupportedFeed, 'The provided URL is not supported' unless parser.present?
  end

  def is_url_accessible?
    response = HTTParty.get(@calendar.source, follow_redirects: true)
    response.code == 200
  rescue
    false
  end

end
