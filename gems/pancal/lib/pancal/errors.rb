# frozen_string_literal: true

module PanCal
  # All PanCal errors carry a machine-readable code symbol so callers can map
  # them to their own user-facing messages (PanCal itself has no I18n).
  class Error < StandardError
    attr_reader :code

    def initialize(message = nil, code: nil)
      @code = code
      super(message)
    end
  end

  # The URL provided is not recognised as a parsable source
  # (and it does not have ld-json data).
  # Codes: :missing_url, :invalid_url, :unsupported, :unknown_reader
  class UnsupportedFeed < Error; end

  # The response status from the URL was not success (200).
  # Mainly for direct HTTP based source types.
  # Codes: :forbidden, :not_found, :unreadable, :unresolvable, :socket_error,
  # :unreachable, :api_key_missing, :api_key_invalid, :api_key_forbidden,
  # :api_rate_limit, :api_error
  class InaccessibleFeed < Error
    attr_reader :http_status

    def initialize(message = nil, code: nil, http_status: nil)
      @http_status = http_status
      super(message, code: code)
    end
  end

  # The response was not valid XML, JSON, ICAL, etc.
  # Codes: :missing_data, :invalid_json, :invalid_ics
  class InvalidResponse < Error; end
end
