# frozen_string_literal: true

require 'test_helper'

class EventsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # create sites and data
    ward = create(:neighbourhood)
    tag = create(:partnership)

    @slugless_site = create_default_site
    @neighbourhood_site = create(:site_local)
    @partnership_site = create(:site)
    @date = DateTime.now.beginning_of_day

    # add neighbourhoods and tags to sites
    @neighbourhood_site.neighbourhoods << ward.region
    @neighbourhood_site.save!

    @partnership_site.neighbourhoods << ward.region
    @partnership_site.tags << tag
    @partnership_site.save!

    # make partners
    @partner = create(:partner, address: create(:address))
    @partner.address.neighbourhood = @neighbourhood_site.neighbourhoods[0]
    @partner.save!

    @partnership_partner = create(:partner)
    @partnership_partner.tags << tag
    @partnership_partner.address.neighbourhood = @neighbourhood_site.neighbourhoods[0]
    @partnership_partner.save!
  end

  test 'site with no slug redirects to find my placecal' do
    get events_url
    assert_response :redirect
  end

  test 'neighbourhood site index page shows all events that are on today and local info' do
    VCR.use_cassette(:import_test_calendar) do
      @calendar = create(:calendar, partner: @partner)
    end
    other_events = create_list(:event, 5, dtstart: @date + 1.hour, calendar: @calendar)
    neighbourhood_events = create_list(:event, 5, dtstart: @date + 1.hour, calendar: @calendar)
    neighbourhood_events.each { |event| event.update(address: @partner.address, partner: @partner) }

    get from_site_slug(@neighbourhood_site, events_path)
    assert_response :success
    assert_select 'title', count: 1, text: "Events & activities in your area | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Events & activities in your area'
    assert_select 'ol article', neighbourhood_events.length
  end

  test 'partnership site index page shows all events that are on today and local info' do
    VCR.use_cassette(:import_test_calendar) do
      @calendar = create(:calendar, partner: @partnership_partner)
    end
    other_events = create_list(:event, 5, dtstart: @date + 1.hour, calendar: @calendar)
    partnership_events = create_list(:event, 5, dtstart: @date + 1.hour, calendar: @calendar)
    partnership_events.each { |event| event.update(address: @partnership_partner.address, partner: @partnership_partner) }

    get from_site_slug(@partnership_site, events_path)
    assert_response :success
    assert_select 'title', count: 1, text: "Events & activities in your area | #{@partnership_site.name}"
    assert_select 'div.hero h4', text: 'The Community Calendar'
    assert_select 'div.hero h1', text: 'Events & activities in your area'
    assert_select 'ol article', partnership_events.length
  end
end
