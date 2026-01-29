# frozen_string_literal: true

module CalendarImporter::Events
  class OutsavvyEvent < LinkedDataEvent
    # OutSavvy uses malformed timestamps like "2025-06-01T11:00:00:00+01:00"
    # The extra ":00" before the timezone causes DateTime.parse to ignore the offset.
    # This override fixes the timestamp before parsing.
    def parse_timestamp(value)
      timestamp = value.to_s

      # Remove the extra seconds component before the timezone offset
      timestamp = timestamp.sub(/:\d{2}([+-])/, '\1') if timestamp.match?(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}:\d{2}[+-]/)

      DateTime.parse timestamp
    rescue Date::Error
      nil
    end
  end
end
