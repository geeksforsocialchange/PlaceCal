# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP server", type: :request do
  def call_tool(arguments)
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "search_events", arguments: } }.to_json,
                 headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream", "Host" => "lvh.me" }
    response.parsed_body["result"]
  end

  it "finds events by place, linking each to its page" do
    ward = create(:riverside_ward)
    event = create(:event, summary: "Repair cafe", address: create(:address, neighbourhood: ward))

    result = call_tool(place: "Riverside")

    expect(result["isError"]).to be(false)
    expect(result["structuredContent"]["events"].first).to include("title" => "Repair cafe", "url" => event.permalink)
    expect(result["content"].first["text"]).to include("Repair cafe")
  end

  it "explains an unknown place" do
    expect(call_tool(place: "Atlantis")).to include("isError" => true)
  end
end
