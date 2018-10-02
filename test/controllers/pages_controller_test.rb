# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_default_site
  end

  test 'should get join page' do
    get join_url
    assert_response :success
  end

  test 'should get bus page' do
    get bus_url
    assert_response :success
  end

  test 'should get privacy page' do
    get privacy_url
    assert_response :success
  end
end
