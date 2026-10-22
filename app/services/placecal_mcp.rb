# frozen_string_literal: true

# The MCP server at /mcp, letting AI assistants search PlaceCal's events.
module PlacecalMcp
  INSTRUCTIONS = <<~TEXT.squish
    PlaceCal lists events from UK community groups, libraries, community centres and charities,
    organised by neighbourhood. Use search_events with a place name (ward, district, county or
    region) or a postcode to answer questions like "what's on near me this week". Link people to
    each event's url for full details.
  TEXT

  # Stateless with plain JSON replies: each request stands alone, so any Puma worker can answer it
  # and nothing is held open. No Host check, as this is a public read-only server, not a local one.
  def self.transport
    @transport ||= MCP::Server::Transports::StreamableHTTPTransport.new(
      MCP::Server.new(name: 'placecal', title: 'PlaceCal', instructions: INSTRUCTIONS, tools: [SearchEventsTool]),
      stateless: true,
      enable_json_response: true,
      serve_subscriptions_listen: false,
      dns_rebinding_protection: false
    )
  end
end
