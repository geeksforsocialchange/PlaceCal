# frozen_string_literal: true

# CalendarImporter - detect calendar url and use appropriate adapter
class CalendarImporter::CalendarImporter
  include CalendarImporter::Exceptions

  PARSERS = [
    CalendarImporter::Parsers::Eventbrite,
    CalendarImporter::Parsers::Ics,
    CalendarImporter::Parsers::ManchesterUni,
    CalendarImporter::Parsers::Meetup,
    CalendarImporter::Parsers::Squarespace,
    CalendarImporter::Parsers::Ticketsolve,

    # leave this last as its detection algorithm downloads and parses the
    # data from the URL, which is slow
    CalendarImporter::Parsers::LdJson
  ].freeze

  def initialize(calendar)
    @calendar = calendar

    validate_feed!
  end

  def parser
    @parser ||=
      if @calendar.importer_mode == 'auto'
        PARSERS.find { |parser| parser.handles_url?(@calendar) }

      else
        importer_mode = patch_legacy_modes(@calendar)
        PARSERS.find { |parser| parser::KEY == importer_mode }
      end
  end

  private

  # This validates the feed URL to ensure that we do support it, and that it's live on the internet
  # As a side effect, it runs CalendarImporter#parser, which sets self.parser to one of the values above
  # This ensures that self.parser is set during calendar_importer_task
  def validate_feed!
    # raise InaccessibleFeed, "The URL could not be reached for calendar #{@calendar.name}" unless url_accessible?

    CalendarImporter::Parsers::Base.read_http_source @calendar.source

    #    begin
    #      response = HTTParty.get(@calendar.source, follow_redirects: true)
    #      raise InaccessibleFeed, "The source URL could not be read (code=#{response.code})" unless response.success?
    #    rescue HTTParty::ResponseError => e
    #      raise InaccessibleFeed, "The source URL could not be resolved (#{e})"
    #    end

    raise UnsupportedFeed, 'The provided URL is not supported' if parser.blank?
  end

  #  def source_response_code
  #    response = HTTParty.get(@calendar.source, follow_redirects: true)
  #    [ response.code, '' ]

  #  rescue StandardError => e
  #    [ -1, e.message ]
  #  end

  def patch_legacy_modes(calendar)
    # older calendars use specific modes to parse ld-json
    # which we will want to migrate over at some point.
    # But as that will be a one-way migration we should verify
    # that there is no problem with the new code before
    # irreversibly altering calendar records
    mode = calendar.importer_mode
    if %w[out-savvy dice-fm].include?(mode)
      'ld-json'
    else
      mode
    end
  end
end
