# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class OutSavvy < Base
    NAME = 'OutSavvy'
    KEY = 'out-savvy'
    DOMAINS = %w[www.outsavvy.com].freeze

    def self.whitelist_pattern
      %r{^https://(www\.)?outsavvy\.com/organiser/.*}
    end

    def download_calendar
      response = HTTParty.get(@url)
      return [] unless response.success?

      doc = Nokogiri::HTML(response.body)
      data_nodes = doc.xpath('//script[@type="application/ld+json"]')
      return [] if data_nodes.empty?

      [].tap do |raw_event_data|
        data_nodes.each do |node|
          data = safely_parse_json(node.inner_html, {})

          case data
          when Hash
            raw_event_data << data

          when Array
            raw_event_data.concat data

          else
            Rails.logger.debug { "Unrecognised RDF type '#{data.class.name}'" }
          end
        end
      end
    end

    def import_events_from(data)
      JSON::LD::API
        .expand(data)
        .map { |event_hash| CalendarImporter::Events::OutSavvyEvent.new(event_hash) }
        .keep_if(&:event_record?)
    end
  end
end
