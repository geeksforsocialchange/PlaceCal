module Parsers
  class DefaultParser

    def initialize(calendar)
      @calendar = calendar
      @url = calendar.url
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def html_sanitize
      # Convert h1 and h2 to h3
      # Strip out all shady tags
      # Convert all html to markdown
    end

	    # Takes a calendar feed and imports it
    # Returns array of events
    def calendar_to_events
      return unless is_url_accessible? @url
      return unless is_domain_supported? @url
      data = download_calendar @url
      return unless has_calendar_updated?(data, @calendar)
      log import_events_from data
    end

    # Frontend output
    def show_supported_calendar_formats
      return list_of_supported_urls
    end

    # AJAX-y things to return a success/failure when URL is pasted
    def is_url_accessible?
      if check
        true
      else
        log some_bullshit
      end
    end

    def is_domain_supported?
      self.class.descendants.each do |descendant|
        return descendant if @url.match(desendent.whitelist_pattern)
      end
    end

    def has_calendar_updated? data, calendar

    end

    def import_events_from data
      # Sanitize before storing
    end

    # Specific matchers define where we accept feeds from

  end
end
