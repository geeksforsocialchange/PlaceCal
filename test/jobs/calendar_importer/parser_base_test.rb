# frozen_string_literal: true

require 'test_helper'

class ParserBaseTest < ActiveSupport::TestCase
  def setup
    blank_calendar = Calendar.new
    @parser = CalendarImporter::Parsers::Base.new(blank_calendar)
  end

  test 'safely_parse_json parses valid JSON' do
    out = @parser.safely_parse_json('{ "data": "nice" }', [])
    assert out.key?('data')
    assert_equal 'nice', out['data']
  end

  test 'safely_parse_json parses missing JSON' do
    out = @parser.safely_parse_json('', [])
    assert_empty out
  end

  test 'safely_parse_json parses badly formed JSON' do
    out = @parser.safely_parse_json('{ "data"', [])
    assert_empty out
  end
end
