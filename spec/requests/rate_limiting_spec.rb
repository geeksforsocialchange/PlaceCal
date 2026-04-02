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

  describe "non-API requests" do
    it "does not throttle non-API paths" do
      101.times do
        get "/"
      end

      expect(response).not_to have_http_status(:too_many_requests)
    end
  end
end
