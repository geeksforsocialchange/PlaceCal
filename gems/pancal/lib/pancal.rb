# frozen_string_literal: true

require 'base64'
require 'digest'
require 'forwardable' # eventbrite_sdk uses Forwardable without requiring it
require 'json'
require 'logger'
require 'time'
require 'uri'

require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'httparty'
require 'icalendar'
require 'icalendar/recurrence'
require 'json/ld'
require 'kramdown'
require 'nokogiri'
require 'rails-html-sanitizer'
require 'uk_postcode'

require_relative 'pancal/version'
require_relative 'pancal/errors'
require_relative 'pancal/source'
require_relative 'pancal/result'
require_relative 'pancal/event'
require_relative 'pancal/events/ics_event'
require_relative 'pancal/events/eventbrite_event'
require_relative 'pancal/events/linked_data_event'
require_relative 'pancal/events/manchester_uni_event'
require_relative 'pancal/events/outsavvy_event'
require_relative 'pancal/events/resident_advisor_event'
require_relative 'pancal/events/squarespace_event'
require_relative 'pancal/events/ticketsolve_event'
require_relative 'pancal/events/ticketsource_event'
require_relative 'pancal/events/tickettailor_event'
require_relative 'pancal/events/wix_event'
require_relative 'pancal/readers/base'
require_relative 'pancal/readers/api_base'
require_relative 'pancal/readers/xml'
require_relative 'pancal/readers/ics'
require_relative 'pancal/readers/eventbrite'
require_relative 'pancal/readers/ld_json'
require_relative 'pancal/readers/manchester_uni'
require_relative 'pancal/readers/meetup'
require_relative 'pancal/readers/outsavvy'
require_relative 'pancal/readers/resident_advisor'
require_relative 'pancal/readers/squarespace'
require_relative 'pancal/readers/ticketsolve'
require_relative 'pancal/readers/ticketsource'
require_relative 'pancal/readers/tickettailor'
require_relative 'pancal/readers/wix'
require_relative 'pancal/detector'

# PanCal — "pandoc for events". Reads event feeds from many sources into a
# canonical event format. No Rails, no database: callers persist checksums
# and resolve locations themselves.
module PanCal
  # Accepts http(s) and webcal URLs
  CALENDAR_URL_REGEX = %r{\A(https?|webcal)://[^\s]+\z}i

  class << self
    attr_writer :logger, :default_time_zone

    def logger
      @logger ||= Logger.new(IO::NULL)
    end

    # Time zone name used when a feed gives local times with no zone
    def default_time_zone
      @default_time_zone ||= 'Europe/London'
    end

    def time_zone
      ActiveSupport::TimeZone[default_time_zone]
    end

    # All reader classes, in detection-cascade order
    def readers
      Detector::READERS
    end

    # Validates the source URL and resolves the reader class for it.
    # Raises UnsupportedFeed / InaccessibleFeed when the URL is missing,
    # malformed, unreachable, or matches no reader.
    def detect(source)
      source = Source.new(url: source) if source.is_a?(String)
      detector = Detector.new(source)
      detector.validate!
      detector.reader
    end

    # Reads a source and returns a Result with canonical events.
    # When the feed's checksum matches source.last_checksum and force is
    # false, parsing is skipped and the result has no events.
    def read(source, force: false, logger: nil)
      reader_class = detect(source)
      reader_class.new(source, logger: logger).read(force: force)
    end
  end
end
