# frozen_string_literal: true

module CalendarImporter::Parsers
  class Outsavvy < LdJson
    NAME = 'OutSavvy'
    KEY = 'outsavvy'
    DOMAINS = %w[outsavvy.com].freeze

    def self.event_class = CalendarImporter::Events::OutsavvyEvent

    def self.allowlist_pattern
      %r{^https://www\.outsavvy\.com/organiser/[^/]*/?$}
    end

    # Recognised from the URL alone, without fetching the page
    def self.handles_url?(calendar)
      calendar.source =~ allowlist_pattern
    end

    # Get event URLs from an organiser page

    def extract_event_urls(organiser_url)
      response_body = Base.read_http_source(organiser_url)

      doc = Nokogiri::HTML(response_body)

      live_events = doc.xpath('//div[@id="live_events"]/div[@id="eventscontent"]/div/*')

      live_events.map { |event| event.xpath('./div/a').attr('href').value }
    end

    def download_calendar
      extract_event_urls(@url).flat_map do |event_url|
        doc = Nokogiri::HTML(Base.read_http_source(event_url))
        with_page_description(Base.parse_ld_json_document(doc), doc)
      end
    end

    private

    # The ld+json description has its tags stripped, which runs every paragraph together.
    def with_page_description(nodes, doc)
      description = doc.at_css('#description .event-description')
      return nodes if description.nil? || description.text.blank?

      description.css('p').select { |paragraph| paragraph.text.blank? }.each(&:remove)
      event_nodes(nodes).each { |node| node['description'] = description.inner_html }
      nodes
    end

    # Events with several dates list them under @graph rather than at the top level.
    def event_nodes(nodes)
      nodes.flat_map { |node| [node, *Array.wrap(node['@graph'])] }.select { |node| node.key?('start_date') }
    end
  end
end
