# frozen_string_literal: true

module PanCal
  # Resolves the reader class for a Source: by KEY when the source names a
  # reader, otherwise via the handles_url? detection cascade. validate!
  # additionally checks the URL is well-formed and reachable.
  class Detector
    READERS = [
      Readers::Eventbrite,
      Readers::Ics,
      Readers::Ticketsource,
      Readers::ManchesterUni,
      Readers::Meetup,
      Readers::Outsavvy,
      Readers::ResidentAdvisor,
      Readers::Squarespace,
      Readers::Ticketsolve,
      Readers::Tickettailor,
      Readers::Wix,

      # leave this last as its detection algorithm downloads and parses the
      # data from the URL, which is slow
      Readers::LdJson
    ].freeze

    def initialize(source)
      @source = source
    end

    def reader
      @reader ||=
        if @source.auto?
          READERS.find { |r| r.handles_url?(@source) }
        elsif @source.reader
          READERS.find { |r| @source.reader.to_s == r::KEY }
        end
    end

    # This validates the feed URL to ensure that we do support it, and that
    # it's live on the internet. As a side effect it resolves #reader, so a
    # successful validate! guarantees reader is set.
    def validate!
      url = @source.url.to_s.strip
      raise UnsupportedFeed.new('The provided URL is missing', code: :missing_url) if url.empty?

      raise UnsupportedFeed.new('The provided URL is not a valid URL', code: :invalid_url) unless CALENDAR_URL_REGEX.match?(url)

      # API-based readers validate connectivity through their own authenticated
      # API calls, and their source URLs may be behind Cloudflare challenges.
      # Check by URL pattern to avoid triggering LdJson's HTTP-based handles_url?.
      api_reader = READERS.find do |r|
        r.requires_api_token? &&
          r.respond_to?(:allowlist_pattern) &&
          url.match?(r.allowlist_pattern)
      end
      if api_reader
        @reader = api_reader
        return
      end

      Readers::Base.read_http_source url

      raise UnsupportedFeed.new('The provided URL is not supported', code: :unsupported) if reader.nil?
    end
  end
end
