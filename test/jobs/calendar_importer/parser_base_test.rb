# frozen_string_literal: true

require 'test_helper'

class ParserBaseTest < ActiveSupport::TestCase
  test 'safely_parse_json parses JSON safely' do
    blank_calendar = Calendar.new
    parser = CalendarImporter::Parsers::Base.new(blank_calendar)

    # valid
    out = parser.safely_parse_json('{ "data": "nice" }', [])
    assert out.has_key?('data')
    assert_equal 'nice', out['data']

    # missing
    out = parser.safely_parse_json('', [])
    assert_equal [], out

    # badly formed
    out = parser.safely_parse_json('{ "data"', [])
    assert_equal [], out
  end

end