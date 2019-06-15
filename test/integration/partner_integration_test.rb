# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @default_site = create_default_site
    @neighbourhood_site = create(:site_local)
    @partner = create(:partner)
  end

  test 'should show basic information' do
    get partner_url(@partner)
    assert_response :success
    assert_select 'title', count: 1, text: "#{@partner.name} | #{@default_site.name}"
    assert_select 'div.hero h4', text: 'The Community Calendar'
    assert_select 'div.hero h1', @partner.name
    assert_select 'p', @partner.short_description
    assert_select 'p', /123 Moss Ln E/
    assert_select 'p', /Manchester/
    assert_select 'p', /M15 5DD/
    assert_select 'p', /#{@partner.public_phone}/
    assert_select 'a[href=?]', "mailto:#{@partner.public_email}"
    assert_select 'a[href=?]', @partner.url

    get "http://#{@neighbourhood_site.slug}.lvh.me/partners/#{@partner.id}"
    assert_response :success
    assert_select 'title', count: 1, text: "#{@partner.name} | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', @partner.name
  end


end
