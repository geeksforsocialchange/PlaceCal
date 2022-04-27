class CalendarImporter::CalendarImporter
  # detect calendar url and use appropriate adapter

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

  def initialize(calendar, options={})
    @calendar = calendar
    @url = calendar.source
    @options = options
  end

  def parse
    validate_feed
    parser.new(@calendar, @url, @options).calendar_to_events
  end

  def validate_feed
    raise InaccessibleFeed, "The URL could not be reached for calendar #{@calendar.name}" unless is_url_accessible?
    raise UnsupportedFeed, "The provided URL is not supported" unless parser.present?
    true
  end

  def is_url_accessible?
    response = HTTParty.get(@url, follow_redirects: true)
    response.code == 200
  rescue
    false
  end

  def parser
    PARSERS.find { |parser| parser.handles_url? @url }
  end
end
