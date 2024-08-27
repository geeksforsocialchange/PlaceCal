# frozen_string_literal: true

module CalendarImporter::Parsers
  class ResidentAdvisor < Base
    NAME = 'Resident Advisor'
    KEY = 'residentadvisor'
    DOMAINS = %w[ra.co].freeze
    RA_ENDPOINT = 'https://ra.co/graphql'
    RA_REGEX = %r{^https://ra\.co/(promoters|clubs)/(\d+)$} # Accept club or promoter URLs

    def self.allowlist_pattern
      RA_REGEX
    end

    def download_calendar
      ra_entity = ra_entity(@url)
      return unless ra_entity

      if ra_entity[0] == :promoters
        get_promoter_events(ra_entity[1])
      elsif ra_entity[0] == :clubs
        get_club_events(ra_entity[1])
      end
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::ResidentAdvisor.new(d) }
    end

    # Converts an RA URL into [(promoter OR club), (id of entity)]
    def ra_entity(url)
      result = RA_REGEX.match(url)
      return false unless result

      [result[1].to_sym, result[2].to_i]
    end

    def get_promoter_events(id)
      # LATEST query is discovered via introspection.
      # I think it gives the next 10 events.
      query = <<~GRAPHQL
        promoter(id: #{id}) {
          id
          name
          email
          events(type: LATEST) {
            id
            title
            content
            startTime
            endTime
            contentUrl
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

    def get_club_events(id)
      # LATEST query is discovered via introspection.
      # I think it gives the next 10 events.
      query = <<~GRAPHQL
        venue(id: #{id}) {
          id
          name
          address
          events(type: LATEST) {
            id
            title
            content
            startTime
            endTime
            contentUrl
          }
        }
      GRAPHQL

      events = query_graphql_endpoint(query)
      events['data']['venue']['events']
    end

    # Send a POST request to the GraphQL endpoint
    # TODO: Migrate into a generic GraphQL base class
    def query_graphql_endpoint(query)
      HTTParty.post(RA_ENDPOINT,
                    body: postify_query_string(query),
                    headers: { 'Content-Type': 'application/json',
                               'Accept': 'application/json',
                               'User-Agent': 'Mozilla/5.0' })
    end

    # Massage a GraphQL query into a post request body
    def postify_query_string(query)
      "{\"query\": \"{#{query}}\"}".gsub("\n", '')
    end
  end
end
