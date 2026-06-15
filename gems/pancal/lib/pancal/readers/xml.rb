# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

module PanCal
  module Readers
    class Xml < Base
      def download_calendar
        parse_xml Base.read_http_source(@url)
      end

      def parse_xml(xml)
        Nokogiri::XML xml
      end
    end
  end
end
