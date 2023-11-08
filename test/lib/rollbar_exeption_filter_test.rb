# frozen_string_literal: true

require 'test_helper'

class RollbarExceptionFilterTest < ActiveSupport::TestCase
  test 'blocks ignorable URL exceptions' do
    bad_paths = [
      # testing original RB filters
      'No route matches [GET] "/old"',
      'No route matches [GET] "/old/thing"',
      'No route matches [GET] "/gate.php?arg=2"',
      'No route matches [GET] "/wp-includes/hello"',
      'No route matches [GET] "/mifs/alpha"',
      'No route matches [GET] "/vendor/beta"',
      'No route matches [GET] "/epa/cappa"',

      # production/staging exceptions
      'No route matches [POST] "/radio.php"',
      'No route matches [HEAD] "/partner/X"',
      'No route matches [HEAD] "/wordpress"',
      'No route matches [GET] "/assets/icons/map/map-shadow-df14333017de880ca0c112fd0084f2597d4cdbd412ea3c6d3c8507621538152f.png"',
      'No route matches [GET] "/assets/datatables.net-bs4/css/dataTable.bootstrap4.css"'
    ]

    bad_paths.each do |bad_path|
      error = ActionController::RoutingError.new(bad_path)

      level = RollbarExceptionFilter.muffle_routing_error(error)

      assert_equal 'ignore', level
    end
  end

  test 'allows non-ignorable URL exceptions' do
    okay_paths = [
      # admin-y paths
      'No route matches [GET] "/partner/123"',
      'No route matches [GET] "/event/56789"',
      'No route matches [GET] "/calendars/56789"',
      'No route matches [GET] "/users/56789"',
      'No route matches [GET] "/sites/56789"',
      'No route matches [GET] "/neighbourhoods/56789"',
      'No route matches [GET] "/tags/56789"',
      'No route matches [GET] "/articles/56789"',
      'No route matches [GET] "/collections/56789"',
      'No route matches [GET] "/supporters/56789"',
      'No route matches [GET] "/jobs/56789"',
      'No route matches [GET] "//56789"'
    ]

    okay_paths.each do |okay_path|
      error = ActionController::RoutingError.new(okay_path)

      level = RollbarExceptionFilter.muffle_routing_error(error)

      assert_equal 'warning', level
    end
  end
end
