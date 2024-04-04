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
    url = @calendar.source.to_s.strip
    raise UnsupportedFeed, 'The provided URL is missing' if url.blank?
    raise UnsupportedFeed, 'The provided URL is not a valid URL' unless Calendar::CALENDAR_REGEX.match?(url)

    CalendarImporter::Parsers::Base.read_http_source url

    raise UnsupportedFeed, 'The provided URL is not supported' if parser.blank?
  end

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
