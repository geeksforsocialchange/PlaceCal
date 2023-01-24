# frozen_string_literal: true

require 'test_helper'

class ParserXmlBaseTest < ActiveSupport::TestCase
  def setup
    blank_calendar = Calendar.new
    @base = CalendarImporter::Parsers::Xml.new(blank_calendar)
  end

  test 'parse_xml parses XML' do
    xml = '<thing></thing>'

    document = @base.parse_xml(xml)
    assert_equal 'thing', document.root.name
  end

  test 'parse_xml handles missing XML' do
    error = assert_raises(CalendarImporter::Exceptions::BadFeedResponse) do
      @base.parse_xml('')
    end

    assert_equal 'The XML response was empty', error.message
  end

  test 'parse_xml handles badly formed XML' do
    bad_xml = '<thing </thing>>'
    error = assert_raises(CalendarImporter::Exceptions::BadFeedResponse) do
      @base.parse_xml(bad_xml)
    end

    assert_equal 'The XML response could not be parsed', error.message
  end
end
