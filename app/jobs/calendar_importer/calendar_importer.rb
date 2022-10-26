# frozen_string_literal: true

# CalendarImporter - detect calendar url and use appropriate adapter
class CalendarImporter::CalendarImporter
  class UnsupportedFeed < StandardError; end
  class InaccessibleFeed < StandardError; end

  PARSERS = [
    CalendarImporter::Parsers::ManchesterUni,
    CalendarImporter::Parsers::Ticketsolve,
    CalendarImporter::Parsers::Ics,
    CalendarImporter::Parsers::Eventbrite,
    CalendarImporter::Parsers::Meetup,
    CalendarImporter::Parsers::Squarespace
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

  # This validates the feed URL to ensure that we do support it, and that it's live on the internet
  # As a side effect, it runs CalendarImporter#parser, which sets self.parser to one of the values above
  # This ensures that self.parser is set during calendar_importer_task
  def validate_feed!
    raise InaccessibleFeed, "The URL could not be reached for calendar #{@calendar.name}" unless url_accessible?
    raise UnsupportedFeed, 'The provided URL is not supported' if parser.blank?
  end

  def url_accessible?
    response = HTTParty.get(@calendar.source, follow_redirects: true)
    response.code == 200
  rescue StandardError
    false
  end
end
