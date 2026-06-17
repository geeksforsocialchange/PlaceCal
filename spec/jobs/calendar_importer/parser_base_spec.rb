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

  describe ".with_http_retries" do
    before { allow(described_class).to receive(:sleep) } # don't actually back off

    it "returns the result without retrying on success" do
      calls = 0
      result = described_class.with_http_retries("ctx") do
        calls += 1
        :ok
      end

      expect(result).to eq(:ok)
      expect(calls).to eq(1)
      expect(described_class).not_to have_received(:sleep)
    end

    it "retries the configured exceptions with backoff, then re-raises" do
      calls = 0
      expect do
        described_class.with_http_retries("ctx", retry_on: [RestClient::TooManyRequests]) do
          calls += 1
          raise RestClient::TooManyRequests
        end
      end.to raise_error(RestClient::TooManyRequests)

      expect(calls).to eq(described_class::HTTP_MAX_RETRIES + 1)
      expect(described_class).to have_received(:sleep).exactly(described_class::HTTP_MAX_RETRIES).times
    end

    it "does not retry exceptions that are not configured" do
      calls = 0
      expect do
        described_class.with_http_retries("ctx", retry_on: [RestClient::TooManyRequests]) do
          calls += 1
          raise RestClient::Unauthorized
        end
      end.to raise_error(RestClient::Unauthorized)

      expect(calls).to eq(1)
    end

    it "retries while retry_if matches, then returns the recovered result" do
      responses = [503, 503, 200]
      index = -1
      result = described_class.with_http_retries("ctx", retry_if: ->(code) { code != 200 }) do
        index += 1
        responses[index]
      end

      expect(result).to eq(200)
      expect(index).to eq(2)
      expect(described_class).to have_received(:sleep).twice
    end

    it "gives up and returns the last result once retries are exhausted" do
      result = described_class.with_http_retries("ctx", retry_if: ->(_) { true }) { 503 }

      expect(result).to eq(503)
      expect(described_class).to have_received(:sleep).exactly(described_class::HTTP_MAX_RETRIES).times
    end
  end

  describe ".read_http_source" do
    it "retries transient 5xx responses and returns the recovered body" do
      allow(described_class).to receive(:sleep)
      unavailable = instance_double(HTTParty::Response, success?: false, code: 503)
      ok = instance_double(HTTParty::Response, success?: true, body: "<html>ok</html>", code: 200)
      allow(HTTParty).to receive(:get).and_return(unavailable, ok)

      expect(described_class.read_http_source("https://example.com")).to eq("<html>ok</html>")
      expect(HTTParty).to have_received(:get).twice
    end

    it "does not retry non-transient responses such as 404" do
      allow(described_class).to receive(:sleep)
      not_found = instance_double(HTTParty::Response, success?: false, code: 404)
      allow(HTTParty).to receive(:get).and_return(not_found)

      expect do
        described_class.read_http_source("https://example.com")
      end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed)
      expect(HTTParty).to have_received(:get).once
    end

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
