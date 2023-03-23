# frozen_string_literal: true

require 'test_helper'

class ParserBaseTest < ActiveSupport::TestCase
  Base = CalendarImporter::Parsers::Base

  test 'safely_parse_json parses valid JSON' do
    out = Base.safely_parse_json('{ "data": "nice" }')
    assert out.key?('data')
    assert_equal 'nice', out['data']
  end

  test 'safely_parse_json parses missing JSON' do
    error = assert_raises(CalendarImporter::Exceptions::InvalidResponse) do
      Base.safely_parse_json('')
    end

    assert_equal 'Source responded with missing JSON', error.message
  end

  test 'safely_parse_json parses badly formed JSON' do
    error = assert_raises(CalendarImporter::Exceptions::InvalidResponse) do
      Base.safely_parse_json('{ "data"')
    end

    assert_equal "Source responded with invalid JSON (783: unexpected token at '{ \"data\"')", error.message
  end

  test 'read_http_source reads remote URL with valid input' do
    VCR.use_cassette(:example_dot_com) do
      response = Base.read_http_source('https://example.com')
      assert response.is_a?(String), 'response should be a string'
    end
  end

  test 'read_http_source raises correct exception with invalid URL' do
    VCR.use_cassette(:invalid_url) do
      error = assert_raises(CalendarImporter::Exceptions::InaccessibleFeed) do
        Base.read_http_source('https://dandilion.gfsc.studio')
      end

      assert_match(/There was a socket error.*Failed to open TCP connection to dandilion.gfsc.studio:443/, error.message)
    end
  end

  test 'read_http_source raises correct exception when URL gives invalid response' do
    # NOTE: this cassette has been hand modified to respond with a 401 code
    VCR.use_cassette(:example_dot_com_bad_response) do
      error = assert_raises(CalendarImporter::Exceptions::InaccessibleFeed) do
        Base.read_http_source('https://example.com')
      end

      assert_equal('The source URL could not be read (code=401)', error.message)
    end
  end
end
