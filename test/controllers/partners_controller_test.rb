# frozen_string_literal: true

require 'test_helper'

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    neighbourhoods = [ create(:neighbourhood), create(:neighbourhood) ]
    # Deliberately saving address twice. (create + save) Second time overwrites neighbourhood.
    addresses = neighbourhoods.map {|n| a=create(:address); a.neighbourhood=n; a.save; a}
    @partners = addresses.map {|a| pa=build(:partner); pa.address=a; pa.save; pa}
    default_site = create_default_site
    default_site.neighbourhoods.append(neighbourhoods)
    default_site.save
    @site = build(:site)
    @site.neighbourhoods.append(neighbourhoods.first)
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
    assert_response :redirect
  end

  test 'should show partner' do
    get partner_url(@partners.first)
    assert_response :success
  end
end
