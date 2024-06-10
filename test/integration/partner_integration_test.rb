# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @slugless_site = create_default_site
    @default_site = create(:site)
    @neighbourhood_site = create(:site_local)
    @partner = create(:partner)
  end

  test 'slugless site should redirect' do
    get partner_url(@partner)
    assert_response :redirect
  end

  test 'should show basic information' do
    get from_site_slug(@default_site, partner_path(@partner))
    assert_response :success
    assert_select 'title', count: 1, text: "#{@partner.name} | #{@default_site.name}"
    assert_select 'div.hero h1', @partner.name
    assert_select 'p', @partner.summary
    assert_select 'p', @partner.description
    assert_select 'p', /123 Moss Ln E/
    assert_select 'p', /Manchester/
    assert_select 'p', /M15 5DD/
    assert_select 'p', /#{@partner.public_phone}/
    assert_select 'a[href=?]', "mailto:#{@partner.public_email}"
    assert_select 'a[href=?]', @partner.url
    assert_select 'h3', 'Opening times'

    get from_site_slug(@neighbourhood_site, partner_path(@partner))
    assert_response :success
    assert_select 'title', count: 1, text: "#{@partner.name} | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', @partner.name
  end

  test 'hides accessibility area when not set' do
    get from_site_slug(@default_site, partner_path(@partner))
    assert_response :success
    assert_select 'details#accessibility-info', count: 0
  end

  test 'has accessibility text' do
    @partner.accessibility_info = 'This is some accessibility informtation'
    @partner.save!

    get from_site_slug(@default_site, partner_path(@partner))
    assert_response :success
    assert_select 'details#accessibility-info', count: 1
  end

  test 'tells you if no calendar is connected' do
    get from_site_slug(@default_site, partner_path(@partner))
    assert_select 'em', 'This partner does not list events on PlaceCal.'
  end

  test 'tells you if no events are connected' do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(:calendar)
      partner = calendar.partner

      get from_site_slug(@default_site, partner_path(partner))
      assert_select 'em', 'This partner has no upcoming events.'
    end
  end

  test 'if theres a few events show them' do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(:calendar)

      @partner.events << create(:event, calendar: calendar)
      @partner.save

      get from_site_slug(@default_site, partner_path(@partner))
      assert_select 'div.event', count: 1
      # Paginator should not show up
      assert_select 'div#paginator', count: 0
    end
  end

  test 'if theres a lot of events show them with a paginator' do
    VCR.use_cassette(:import_test_calendar) do
      calendar = create(:calendar)

      @partner.events << create_list(:event, 30, calendar: calendar)
      @partner.save

      get from_site_slug(@default_site, partner_path(@partner))
      assert_select 'div.event', minimum: 5
      # Paginator should show up
      assert_select 'div#paginator', count: 1
    end
  end
end
