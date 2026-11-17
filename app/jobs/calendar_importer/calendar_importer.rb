# frozen_string_literal: true

# CalendarImporter - detect calendar url and use appropriate adapter
class CalendarImporter::CalendarImporter
  include CalendarImporter::Exceptions

  PARSERS = [
    CalendarImporter::Parsers::Eventbrite,
    CalendarImporter::Parsers::Ics,
    CalendarImporter::Parsers::Ticketsource,
    CalendarImporter::Parsers::ManchesterUni,
    CalendarImporter::Parsers::Meetup,
    CalendarImporter::Parsers::Outsavvy,
    CalendarImporter::Parsers::ResidentAdvisor,
    CalendarImporter::Parsers::Squarespace,
    CalendarImporter::Parsers::Ticketsolve,
    CalendarImporter::Parsers::Tickettailor,
    CalendarImporter::Parsers::Wix,

    # leave this last as its detection algorithm downloads and parses the
    # data from the URL, which is slow
    CalendarImporter::Parsers::LdJson
  ].freeze

  # @param key [String, nil]
  # @return [Class, nil] the parser whose KEY is key
  def self.parser_for_key(key)
    PARSERS.find { |parser| parser::KEY == key }
  end

  # @return [Array<Class>] parsers that read an API with the calendar's token
  def self.api_token_parsers
    PARSERS.select(&:requires_api_token?)
  end

  # @return [Array<Class>] parsers offered to admins, in PARSERS order
  def self.public_parsers
    PARSERS.select { |parser| parser::PUBLIC }
  end

  def initialize(calendar)
    @calendar = calendar
  end

  # @return [Class, nil] the parser for the calendar, or nil when none is found
  def parser
    @parser ||= parser_skipping_source_check || parser_for_mode
  end

  # Checks the source URL is valid, reachable and has a parser.
  # @raise [UnsupportedFeed] when the URL is blank or invalid, or no parser is found
  # @raise [InaccessibleFeed] when the source can't be fetched
  def check_source!
    raise UnsupportedFeed, 'The provided URL is missing' if url.blank?
    raise UnsupportedFeed, 'The provided URL is not a valid URL' unless Validation::CALENDAR_URL_REGEX.match?(url)
    return if parser_skipping_source_check

    CalendarImporter::Parsers::Base.read_http_source url

    raise UnsupportedFeed, 'The provided URL is not supported' if parser.blank?
  end

  private

  def url
    @calendar.source.to_s.strip
  end

  # By URL pattern alone: these sources may sit behind Cloudflare challenges, and detection can fetch the page
  def parser_skipping_source_check
    PARSERS.find do |parser|
      parser.skips_source_check? &&
        parser.respond_to?(:allowlist_pattern) &&
        url.match?(parser.allowlist_pattern)
    end
  end

  def parser_for_mode
    # Calendars saved before Manchester University had a key have a blank mode; detect their parser
    if @calendar.importer_mode.blank? || @calendar.importer_mode == 'auto'
      PARSERS.find { |parser| parser.handles_url?(@calendar) }
    else
      self.class.parser_for_key(patch_legacy_modes(@calendar))
    end
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
