# frozen_string_literal: true

# test/controllers/components_test.rb
require 'test_helper'

class ComponentControllerTest < ActionDispatch::IntegrationTest
  teardown do
    # Check each component loads using the options listed
    assert_response :success
    # Check we actually have some options, of course
    assert_select 'h2',
                  count: 0,
                  text: "Hint:To see your component make sure you've created stubs:"
  end

  test 'should get bus routes' do
    get '/styleguide/styleguide/bus_route'
  end

  test 'should get breadcrumb' do
    get '/styleguide/styleguide/breadcrumb'
  end

  test 'should get event' do
    get '/styleguide/styleguide/event'
  end

  test 'should get hero' do
    get '/styleguide/styleguide/hero'
  end

  test 'should get footer' do
    get '/styleguide/styleguide/footer'
  end

  test 'should get map' do
    get '/styleguide/styleguide/map'
  end

  test 'should get navigation' do
    get '/styleguide/styleguide/navigation'
  end

  test 'should get paginator' do
    get '/styleguide/styleguide/paginator'
  end

  test 'should get place' do
    get '/styleguide/styleguide/place'
  end
end
