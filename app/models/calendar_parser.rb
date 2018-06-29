class CalendarParser
  class UnSupportedFeed < StandardError; end
  class InAccessibleFeed < StandardError; end

  PARSERS = [Parsers::ManchesterUni, Parsers::Zarts, Parsers::Facebook, Parsers::Ics].freeze

  def initialize(calendar, options={})
    @calendar = calendar
    @url = calendar.source
    @options = options
  end


  def self.list_of_supported_urls
    PARSERS.dup.collect { |descendant| descendant.whitelist_pattern }
  end

  def parse
    validate_feed
    parser.new(@calendar, @url, @options).calendar_to_events
  end

  def validate_feed
    raise InAccessibleFeed, "The url #{@url} could not be reached for calendar #{@calendar.name}" unless is_url_accessible?
    raise UnSupportedFeed, "The provided url #{@url} is not supported" unless parser.present?
    true
  end

  def is_url_accessible?
    response = HTTParty.get(@url, follow_redirects: true)
    response.code == 200
  end


  def parser
    PARSERS.each do |parse|
      return parse if @url.match(parse.whitelist_pattern)
    end
  end
end
