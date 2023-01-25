# frozen_string_literal: true

require 'test_helper'

class ParserXmlBaseTest < ActiveSupport::TestCase
  def setup
    blank_calendar = Calendar.new
    @base = CalendarImporter::Parsers::Xml.new(blank_calendar)
  end
end
