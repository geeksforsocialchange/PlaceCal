# frozen_string_literal: true

# CalendarImporter - detect calendar url and use appropriate adapter
class CalendarImporter::CalendarImporter
  class UnsupportedFeed < StandardError; end
  class InaccessibleFeed < StandardError; end

  DETECTABLE_PARSERS = [
    CalendarImporter::Parsers::DiceFm,
    CalendarImporter::Parsers::Eventbrite,
    CalendarImporter::Parsers::Ics,
    CalendarImporter::Parsers::ManchesterUni,
    CalendarImporter::Parsers::Meetup,
    CalendarImporter::Parsers::OutSavvy,
    CalendarImporter::Parsers::Squarespace,
    CalendarImporter::Parsers::Ticketsolve
  ].freeze

  MANUAL_PARSERS = (DETECTABLE_PARSERS.dup.concat [
    CalendarImporter::Parsers::LdJson
    # CalendarImporter::Parsers::RssFeed
  ]).freeze

  def initialize(calendar)
    @calendar = calendar

    validate_feed!
  end

  def parser
    return @parser if @parser

    if @calendar.importer_mode == 'auto'
      @parser = DETECTABLE_PARSERS.find { |parser| parser.handles_url?(@calendar.source) }

      if @parser.blank?
        # TODO: now try to detect ld+json
        try_parser = CalendarImporter::Parsers::LdJson.new(@calendar)
        nodes = try_parser.download_calendar
        @parser = CalendarImporter::Parsers::LdJson if nodes.present?
      end

      return @parser
    end

    @parser = MANUAL_PARSERS.find { |parser| parser::KEY == @calendar.importer_mode }
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
