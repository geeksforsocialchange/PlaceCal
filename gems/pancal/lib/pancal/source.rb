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
      @reader = reader || :auto
      @token = token
      @last_checksum = last_checksum
    end

    def auto?
      reader.to_s.empty? || reader.to_s == 'auto'
    end
  end
end
