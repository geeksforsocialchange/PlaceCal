# frozen_string_literal: true

module PanCal
  # Everything PanCal needs to know about a feed. Immutable: readers report
  # the new checksum on the Result and the caller persists it.
  class Source
    attr_reader :url, :reader, :token, :last_checksum

    # url:           feed URL (http, https or webcal)
    # reader:        a reader KEY string (e.g. 'eventbrite'), or :auto to
    #                run the detection cascade
    # token:         API key for token-based readers (ticketsource,
    #                tickettailor, eventbrite)
    # last_checksum: checksum from the previous read, for skip-if-unchanged
    def initialize(url:, reader: :auto, token: nil, last_checksum: nil)
      @url = url
      @reader = reader
      @token = token
      @last_checksum = last_checksum
    end

    # Only the literal 'auto' runs the detection cascade. A nil reader is NOT
    # auto: it names no reader and fails validation, matching how PlaceCal's
    # importer treated a NULL importer_mode.
    def auto?
      reader.to_s == 'auto'
    end
  end
end
