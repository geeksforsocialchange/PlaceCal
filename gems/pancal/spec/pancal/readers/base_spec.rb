# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/parser_base_spec.rb.
# The I18n-driven message expectations are now the gem's literal messages
# (PanCal has no I18n); the machine-readable error codes are asserted too.

RSpec.describe PanCal::Readers::Base do
  describe '.safely_parse_json' do
    it 'parses valid JSON' do
      out = described_class.safely_parse_json('{ "data": "nice" }')

      expect(out).to have_key('data')
      expect(out['data']).to eq('nice')
    end

    it 'raises for missing JSON' do
      expect do
        described_class.safely_parse_json('')
      end.to raise_error(PanCal::InvalidResponse, 'Source responded with missing JSON') do |error|
        expect(error.code).to eq(:missing_data)
      end
    end

    it 'raises for badly formed JSON' do
      expect do
        described_class.safely_parse_json('{ "data"')
      end.to raise_error(PanCal::InvalidResponse, /Source responded with invalid JSON/) do |error|
        expect(error.code).to eq(:invalid_json)
      end
    end
  end

  describe '.read_http_source' do
    it 'reads remote URL with valid input' do
      VCR.use_cassette(:example_dot_com) do
        response = described_class.read_http_source('https://example.com')

        expect(response).to be_a(String)
      end
    end

    it 'raises correct exception with invalid URL' do
      # The original spec used an empty VCR cassette (:invalid_url) so the
      # request hit real DNS and failed with a SocketError. The gem suite
      # stubs the SocketError instead, to keep the test offline; the
      # exception mapping under test is unchanged.
      stub_request(:get, 'https://dandilion.gfsc.studio')
        .to_raise(SocketError.new('Failed to open TCP connection to dandilion.gfsc.studio:443 (getaddrinfo: nodename nor servname provided, or not known)'))

      expect do
        described_class.read_http_source('https://dandilion.gfsc.studio')
      end.to raise_error(PanCal::InaccessibleFeed,
                         /There was a socket error.*Failed to open TCP connection to dandilion.gfsc.studio:443/) do |error|
        expect(error.code).to eq(:socket_error)
      end
    end

    it 'raises correct exception when URL gives invalid response' do
      # NOTE: this cassette has been hand modified to respond with a 401 code
      VCR.use_cassette(:example_dot_com_bad_response) do
        expect do
          described_class.read_http_source('https://example.com')
        end.to raise_error(PanCal::InaccessibleFeed, 'The source URL could not be read (code=401)') do |error|
          expect(error.code).to eq(:unreadable)
          expect(error.http_status).to eq(401)
        end
      end
    end

    it 'raises a helpful message for 403 forbidden responses' do
      VCR.use_cassette(:example_dot_com_403_response) do
        expect do
          described_class.read_http_source('https://example.com')
        end.to raise_error(PanCal::InaccessibleFeed, 'The source URL is not public or is missing') do |error|
          expect(error.code).to eq(:forbidden)
          expect(error.http_status).to eq(403)
        end
      end
    end

    it 'raises a helpful message for 404 not found responses' do
      VCR.use_cassette(:example_dot_com_404_response) do
        expect do
          described_class.read_http_source('https://example.com')
        end.to raise_error(PanCal::InaccessibleFeed, 'The source URL could not be found') do |error|
          expect(error.code).to eq(:not_found)
          expect(error.http_status).to eq(404)
        end
      end
    end
  end
end
