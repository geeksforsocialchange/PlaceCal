# frozen_string_literal: true

require 'test_helper'

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partners = [ create(:partner), create(:partner) ]
    @site = build(:site)
    @site.turfs.append(@partners.first.turfs.first)
    @site.save
  end

  test 'should get index without subdomain' do
    get url_for controller: "partners", subdomain: false
    assert_response :success
    assert_select "ul.partners li", 2
  end

  test 'should get index with configured subdomain' do
    get url_for controller: "partners", subdomain: @site.slug
    assert_response :success
    assert_select "ul.partners li", 1
  end

  test 'should get index with unknown subdomain' do
    get url_for controller: "partners", subdomain: "notaknownsubdomain"
    assert_response :success
    assert_select "ul.partners li", 2
  end

  test 'should show partner' do
    get partner_url(@partners.first)
    assert_response :success
  end
end
