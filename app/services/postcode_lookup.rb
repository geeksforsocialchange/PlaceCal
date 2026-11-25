# frozen_string_literal: true

# Looks up a UK postcode with the configured geocoder (postcodes.io, or Normal Island data locally),
# telling a postcode that doesn't exist apart from a lookup service that isn't responding.
module PostcodeLookup
  # Raised when the lookup service can't be reached or answers with an error
  class Unavailable < StandardError; end

  # The errors config/initializers/geocoder.rb tells Geocoder to raise rather than swallow
  OUTAGE_ERRORS = [
    SocketError, Errno::ECONNREFUSED, Geocoder::NetworkError, Timeout::Error, Geocoder::LookupTimeout,
    Geocoder::ServiceUnavailable, Geocoder::OverQueryLimitError, Geocoder::ResponseParseError
  ].freeze

  # @param postcode [String]
  # @return [Hash, nil] the postcodes.io result data, or nil when the postcode doesn't exist
  # @raise [Unavailable] when the lookup service isn't responding
  def self.call(postcode)
    cache = ActiveSupport::IsolatedExecutionState[:postcode_lookup_cache]
    return cache[postcode] if cache&.key?(postcode)

    result = Geocoder.search(postcode).first&.data
    cache[postcode] = result if cache
    result
  rescue *OUTAGE_ERRORS => e
    raise Unavailable, "Postcode lookup failed: #{e.class}: #{e.message}"
  end

  # Looks each postcode up once within the block; an outage is not remembered
  def self.cached
    previous = ActiveSupport::IsolatedExecutionState[:postcode_lookup_cache]
    ActiveSupport::IsolatedExecutionState[:postcode_lookup_cache] = previous || {}
    yield
  ensure
    ActiveSupport::IsolatedExecutionState[:postcode_lookup_cache] = previous
  end

  # Like call, but treats an outage as no result, for callers with no way to report it
  # @return [Hash, nil]
  def self.call_or_nil(postcode)
    call(postcode)
  rescue Unavailable => e
    Rails.logger.warn(e.message)
    nil
  end
end
