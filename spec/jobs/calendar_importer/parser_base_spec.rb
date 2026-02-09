# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Base do
  describe ".safely_parse_json" do
    it "parses valid JSON" do
      out = described_class.safely_parse_json('{ "data": "nice" }')

      expect(out).to have_key("data")
      expect(out["data"]).to eq("nice")
    end

    it "raises for missing JSON" do
      expect do
        described_class.safely_parse_json("")
      end.to raise_error(CalendarImporter::Exceptions::InvalidResponse, "Source responded with missing JSON")
    end

    it "raises for badly formed JSON" do
      expect do
        described_class.safely_parse_json('{ "data"')
      end.to raise_error(CalendarImporter::Exceptions::InvalidResponse, /Source responded with invalid JSON/)
    end
  end

  describe ".read_http_source" do
    it "reads remote URL with valid input" do
      VCR.use_cassette(:example_dot_com) do
        response = described_class.read_http_source("https://example.com")

        expect(response).to be_a(String)
      end
    end

    it "raises correct exception with invalid URL" do
      VCR.use_cassette(:invalid_url) do
        expect do
          described_class.read_http_source("https://dandilion.gfsc.studio")
        end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed, /There was a socket error.*Failed to open TCP connection to dandilion.gfsc.studio:443/)
      end
    end

    it "raises correct exception when URL gives invalid response" do
      # NOTE: this cassette has been hand modified to respond with a 401 code
      VCR.use_cassette(:example_dot_com_bad_response) do
        expect do
          described_class.read_http_source("https://example.com")
        end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed, I18n.t("admin.calendars.wizard.source.unreadable", code: 401))
      end
    end

    it "raises a helpful message for 403 forbidden responses" do
      VCR.use_cassette(:example_dot_com_403_response) do
        expect do
          described_class.read_http_source("https://example.com")
        end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed, I18n.t("admin.calendars.wizard.source.forbidden"))
      end
    end

    it "raises a helpful message for 404 not found responses" do
      VCR.use_cassette(:example_dot_com_404_response) do
        expect do
          described_class.read_http_source("https://example.com")
        end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed, I18n.t("admin.calendars.wizard.source.not_found"))
      end
    end
  end
end
