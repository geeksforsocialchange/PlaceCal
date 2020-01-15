# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    create_default_site
  end

  test 'should get home page' do
    get root_path
    assert_response :success
  end

  test 'should get find a PlaceCal near you page' do
    get find_placecal_path
    assert_response :success
  end

  test 'should get pages for each group' do
    get community_groups_path
    assert_response :success

    get metropolitan_areas_path
    assert_response :success

    get vcses_path
    assert_response :success

    get housing_providers_path
    assert_response :success

    get social_prescribers_path
    assert_response :success

    get culture_tourism_path
    assert_response :success
  end

  test 'should get our story page' do
    get our_story_path
    assert_response :success
  end

  test 'should get join page' do
    get join_path
    assert_response :success
  end

  test 'should get privacy page' do
    get privacy_url
    assert_response :success
  end
end
