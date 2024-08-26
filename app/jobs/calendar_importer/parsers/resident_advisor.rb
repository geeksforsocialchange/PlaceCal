# frozen_string_literal: true

module CalendarImporter::Parsers
  class ResidentAdvisor < Base
    NAME = 'ResidentAdvisor'
    KEY = 'residentadvisor'
    DOMAINS = %w[ra.co].freeze
    RA_ENDPOINT = 'https://ra.co/graphql'
    RA_REGEX = %r{^https://ra\.co/(promoters|clubs)/(\d+)$} # Accept club or promoter URLs

    def self.allowlist_pattern
      RA_REGEX
    end

    # Takes an URL
    # Returns [(promoter OR club), id of entity]
    def self.ra_entity(url)
      result = RA_REGEX.match(url)
      return false unless result

      [result[1].to_sym, result[2].to_i]
    end

    def download_calendar
      ra_entity = ra_entity(@url)
      return unless ra_entity

      # response_body = Base.read_http_source(api_url)

      Base.safely_parse_json response_body
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::MeetupEvent.new(d) }
    end

    def self.get_promoter_events(id)
      query = <<~GRAPHQL
        promoter(id: #{id}) {
          id
          name
          email
          events(type: FIRST) {
            id
            title
            content
            startTime
            endTime
            venue {
              id
              name
              address
            }
          }
        }
      GRAPHQL

      events = query_graphql_endpoint(query)
      events['data']['promoter']['events']
    end

    # Massage the GraphQL query into a post request body
    def self.postify_query_string(query)
      "{\"query\": \"{#{query}}\"}".gsub("\n", '')
    end

    def self.query_graphql_endpoint(query)
      HTTParty.post(RA_ENDPOINT,
                    body: postify_query_string(query),
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'User-Agent': 'Mozilla/5' })
    end
  end
end
