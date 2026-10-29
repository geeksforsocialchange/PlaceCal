# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP server", type: :request do
  def rpc(method, params = {})
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method:, params: }.to_json,
                 headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream", "Host" => "lvh.me" }
    response.parsed_body
  end

  def call_tool(arguments)
    rpc("tools/call", name: "search_events", arguments:)["result"]
  end

  it "answers initialize as a JSON-RPC 2.0 server offering tools" do
    body = rpc("initialize", protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "spec", version: "1" })

    expect(body).to include("jsonrpc" => "2.0", "id" => 1)
    expect(body["result"]["capabilities"]).to have_key("tools")
    expect(body["result"]["serverInfo"]["name"]).to be_present
  end

  it "lists the search_events tool with its input schema" do
    tool = rpc("tools/list")["result"]["tools"].find { |t| t["name"] == "search_events" }

    expect(tool["inputSchema"]["properties"]).to have_key("place")
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

  it "shows a person in a browser how to connect it, leaving MCP clients the protocol" do
    get "/mcp", headers: { "Accept" => "text/html", "Host" => "lvh.me" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(ERB::Util.html_escape(I18n.t("directory.pages.mcp.hero_title")), "#{Site::DIRECTORY_URL}/mcp")

    get "/mcp", headers: { "Accept" => "application/json, text/event-stream", "Host" => "lvh.me" }
    expect(response).to have_http_status(:method_not_allowed)
  end
end
