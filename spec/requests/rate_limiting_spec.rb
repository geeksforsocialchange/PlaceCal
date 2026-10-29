# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.reset!
  end

  describe "API throttling" do
    it "allows requests under the limit" do
      post "/api/v1/graphql", params: { query: "{ ping }" }
      expect(response).to have_http_status(:ok)
    end

    it "returns 429 when exceeding the limit" do
      100.times do
        post "/api/v1/graphql", params: { query: "{ ping }" }
      end

      post "/api/v1/graphql", params: { query: "{ ping }" }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "returns JSON error for throttled API requests" do
      101.times do
        post "/api/v1/graphql", params: { query: "{ ping }" }
      end

      body = response.parsed_body
      expect(body["errors"].first["message"]).to eq("Rate limit exceeded. Try again later.")
    end
  end

  describe "MCP throttling" do
    def list_tools(path)
      post path, params: { jsonrpc: "2.0", id: 1, method: "tools/list" }.to_json,
                 headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream", "Host" => "lvh.me" }
    rescue ActionController::RoutingError
      nil
    end

    it "returns 429 when exceeding the limit" do
      60.times { list_tools("/mcp") }

      list_tools("/mcp")
      expect(response).to have_http_status(:too_many_requests)
    end

    it "counts requests with a format extension against the same limit" do
      30.times { list_tools("/mcp") }
      30.times { list_tools("/mcp.json") }

      list_tools("/mcp.json")
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "non-API requests" do
    it "does not throttle non-API paths" do
      101.times do
        get "/"
      end

      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
