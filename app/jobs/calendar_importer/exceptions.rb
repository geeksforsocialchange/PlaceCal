# frozen_string_literal: true

module CalendarImporter
  module Exceptions
    # The URL provided is not recognised as a parsable source
    # (and it does not have ld-json data).
    class UnsupportedFeed < StandardError; end

    # The response status from the URL was not success (200).
    # Mainly for direct HTTP based source types.
    class InaccessibleFeed < StandardError; end

    # An API answered 404 for one record, which some callers read as "there isn't one".
    class ApiNotFound < InaccessibleFeed; end

    # The response was not valid XML, JSON, ICAL, etc.
    class InvalidResponse < StandardError; end

    # The source kept failing after retries, so the import is skipped and the calendar's events are left as they were.
    class SourceUnavailable < StandardError; end
  end
end
