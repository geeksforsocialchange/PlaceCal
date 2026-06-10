# frozen_string_literal: true

module PanCal
  # What a read produces. The caller is responsible for persisting checksum
  # if it wants skip-if-unchanged behaviour on the next read.
  class Result
    attr_reader :events, :checksum, :reader_key, :notices

    def initialize(events:, checksum:, changed:, reader_key:, notices: [])
      @events = events
      @checksum = checksum
      @changed = changed
      @reader_key = reader_key
      @notices = notices
    end

    def changed?
      @changed
    end
  end
end
