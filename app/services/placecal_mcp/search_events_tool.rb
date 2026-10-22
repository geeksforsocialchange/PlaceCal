# frozen_string_literal: true

module PlacecalMcp
  class SearchEventsTool < MCP::Tool
    MAX_RESULTS = 50

    tool_name 'search_events'
    title 'Find local community events'
    description <<~TEXT.squish
      Find community events listed on PlaceCal, a UK directory of local groups, libraries,
      community centres and charities. Search by UK place name or postcode, optionally narrowed
      by dates, keyword or category. Returns upcoming events with times, venue, organiser and a
      link to the event page.
    TEXT
    annotations(read_only_hint: true, open_world_hint: false)
    input_schema(
      properties: {
        place: { type: 'string', description: 'UK ward, district, county or region name, e.g. "Hulme" or "Manchester"' },
        postcode: { type: 'string', description: 'UK postcode, e.g. "M15 5FS"' },
        from_date: { type: 'string', description: 'Earliest start date, YYYY-MM-DD. Defaults to now' },
        to_date: { type: 'string', description: 'Latest start date, YYYY-MM-DD, inclusive' },
        keyword: { type: 'string', description: 'Text to find in event titles and descriptions, e.g. "yoga"' },
        category: { type: 'string', description: 'Category name, e.g. "Health & Wellbeing"' },
        limit: { type: 'integer', minimum: 1, maximum: MAX_RESULTS, description: 'Most events to return, default 20' }
      }
    )

    class << self
      def call(server_context: nil, **args) # rubocop:disable Lint/UnusedMethodArgument
        search = EventSearch.new(
          from: parse_date(args[:from_date])&.beginning_of_day || Time.zone.now,
          to: parse_date(args[:to_date])&.end_of_day,
          postcode: args[:postcode], place: args[:place], query: args[:keyword], category: args[:category]
        )
        limit = (args[:limit] || 20).to_i.clamp(1, MAX_RESULTS)
        events = search.call.includes(:organiser, :online_address, address: :neighbourhood).limit(limit).to_a
        results = events.map { |event| result(event) }

        MCP::Tool::Response.new([{ type: 'text', text: summary(results, search.neighbourhoods) }],
                                structured_content: { events: results })
      rescue EventSearch::Error, Date::Error => e
        MCP::Tool::Response.new([{ type: 'text', text: e.message }], error: true)
      end

      private

      def parse_date(value)
        Date.iso8601(value).in_time_zone if value.present?
      end

      def result(event)
        {
          title: event.summary,
          starts_at: event.dtstart.in_time_zone.iso8601,
          ends_at: event.dtend&.in_time_zone&.iso8601,
          venue: event.partner_at_location&.name,
          address: event.location.presence,
          online_url: event.online_address&.url,
          organiser: event.organiser&.name,
          repeats: event.repeat_frequency,
          url: event.permalink
        }.compact
      end

      def summary(results, neighbourhoods)
        area = neighbourhoods.map { |n| "#{n.name} (#{n.unit})" }.uniq.join(', ')
        heading = area.present? ? "#{results.size} events in #{area}" : "#{results.size} events"
        lines = results.map do |r|
          ["#{r[:starts_at]}: #{r[:title]}", r[:venue] || r[:address], r[:organiser] && "by #{r[:organiser]}", r[:url]].compact.join(' | ')
        end
        [heading, *lines].join("\n")
      end
    end
  end
end
