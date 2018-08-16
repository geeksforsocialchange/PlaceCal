# frozen_string_literal: true

require 'test_helper'

class PlacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @places = [ create(:place), create(:place) ]
    @site = build(:site)
    @site.turfs.append(@places.first.turfs.first)
    @site.save
  end

  test 'should get index without subdomain' do
    get url_for controller: "places", subdomain: false
    assert_response :success
    assert_select "ul.places li", 2
  end

  test 'should get index with configured subdomain' do
    get url_for controller: "places", subdomain: @site.slug
    assert_response :success
    assert_select "ul.places li", 1
  end

  test 'should get index with unknown subdomain' do
    get url_for controller: "places", subdomain: "notaknownsubdomain"
    assert_response :success
    assert_select "ul.places li", 2
  end

  test 'should show place' do
    get place_url(@places.first)
    assert_response :success
  end
end
