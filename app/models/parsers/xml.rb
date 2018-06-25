# frozen_string_literal: true

module Parsers
  class Xml
  	def initialize(file, params = {})
      @file = file
      @params = params
    end

    def download_calendar
      xml = HTTParty.get(@file, follow_redirects: true).body
      Nokogiri::XML(xml)
    end
  end
end
