# frozen_string_literal: true

require 'test_helper'

class ActiveSupport::TestCase
  def self.context(_description)
    yield
  end
end

class MapMarkersConcernTest < ActiveSupport::TestCase
  class FakeController < ApplicationController
    include MapMarkers
  end

  def controller
    @controller ||= FakeController.new
  end

  context 'get_map_markers' do
    test 'returns empty array if empty input' do
      markers = controller.get_map_markers([])
      assert_empty markers
    end

    test 'returns payload for partners' do
      partners = create_list(:partner, 10)
      output = controller.get_map_markers(partners)
      assert_equal 10, output.length

      entry = output.first
      assert_field entry, :lat
      assert_field entry, :lon
      assert_field entry, :name
      assert_field entry, :id
    end

    test 'returns payload for addresses' do
      addresses = create_list(:address, 10)
      output = controller.get_map_markers(addresses)
      assert_equal 10, output.length

      entry = output.first
      assert_field entry, :lat
      assert_field entry, :lon
    end

    test 'skips partners with no service areas when flagged' do
      neighbourhood = neighbourhoods(:one)

      # no service areas
      partners = create_list(:partner, 5)

      # service areas
      5.times do
        partner = create(:partner)
        partner.service_area_neighbourhoods << neighbourhood

        partners << partner
      end

      output = controller.get_map_markers(partners, true)
      assert_equal 5, output.length
    end

    test 'cam turn events into markers' do
      VCR.use_cassette(:import_test_calendar) do
        calendar = create(:calendar)
        events = create_list(:event, 10, calendar: calendar)
        output = controller.get_map_markers(events)
        assert_equal 10, output.length
      end
    end
  end
end
