# frozen_string_literal: true

module Parsers
  class Xml < Base
    def download_calendar
      xml = HTTParty.get(@url, follow_redirects: true).body
      Nokogiri::XML(xml)
    end
  end
end
