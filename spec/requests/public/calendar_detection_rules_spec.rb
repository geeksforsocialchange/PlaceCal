# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calendar detection rules API", type: :request do
  describe "GET /api/v1/calendar_detection_rules" do
    let(:public_parsers) do
      CalendarImporter::CalendarImporter::PARSERS.select { |parser| parser::PUBLIC }
    end

    let(:parsed) { response.parsed_body }

    before { get "http://lvh.me/api/v1/calendar_detection_rules" }

    it "returns a versioned JSON payload" do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(parsed["version"]).to eq(CalendarDetectionRules::SCHEMA_VERSION)
    end

    it "includes every public parser and no private ones" do
      keys = parsed["parsers"].map { |parser| parser["key"] }
      expect(keys).to match_array(public_parsers.map { |parser| parser::KEY })
      expect(parsed["parsers"].length).to eq(public_parsers.length)
    end

    it "exports url patterns with pattern and flags" do
      eventbrite = parsed["parsers"].find { |parser| parser["key"] == "eventbrite" }
      expect(eventbrite["url_patterns"]).to eq(
        [{ "pattern" => '^https://www\.eventbrite\.(com|co\.uk)/o/[A-Za-z0-9-]+', "flags" => "" }]
      )
      expect(eventbrite["domains"]).to include("www.eventbrite.co.uk")
    end

    it "flags exactly the API-token parsers" do
      token_keys = parsed["parsers"].select { |parser| parser["requires_api_token"] }.map { |parser| parser["key"] }
      expect(token_keys).to contain_exactly("ticketsource", "tickettailor")
    end

    it "flags exactly the content-detection parsers" do
      detection = parsed["parsers"].filter_map do |parser|
        [parser["key"], parser["content_detection"]] if parser["content_detection"]
      end
      expect(detection).to contain_exactly(
        %w[squarespace squarespace],
        %w[wix wix],
        %w[ld-json ld_json]
      )
    end

    it "allows cross-origin requests from browser extensions" do
      get "http://lvh.me/api/v1/calendar_detection_rules",
          headers: { "Origin" => "moz-extension://0000-1111" }
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end

    it "is publicly cacheable and supports conditional requests" do
      expect(response.headers["Cache-Control"]).to include("public")
      etag = response.headers["ETag"]
      expect(etag).to be_present

      get "http://lvh.me/api/v1/calendar_detection_rules", headers: { "If-None-Match" => etag }
      expect(response).to have_http_status(:not_modified)
    end
  end
end
