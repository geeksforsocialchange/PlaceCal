# frozen_string_literal: true

require 'test_helper'

class EventsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @default_site = create_default_site
    @neighbourhood_site = create(:site_local)
    @regional_neighbourhood_site = create(:site_local)

    # Create one set of events for the default site
    date = DateTime.now.beginning_of_day
    @default_site_events = create_list :event, 5, dtstart: date + 1.hour
    @default_site_events.each do |event|
      next if @default_site.neighbourhoods.include? event.neighbourhood

      @default_site.neighbourhoods << event.neighbourhood
    end

    # Create another set for the neighbourhood site
    @neighbourhood_site_events = create_list :event, 5, dtstart: date + 1.hour
    @neighbourhood2 = create(:neighbourhood)
    @neighbourhood_site_events.each do |event|
      event.address.update(neighbourhood: @neighbourhood2)
    end
    @neighbourhood_site.neighbourhoods << @neighbourhood2


    # Make a ward, add events to that ward
    @ward = create(:neighbourhood)
    @regional_ward_events = create_list :event, 5, dtstart: date + 1.hour
    @regional_ward_events.each { |event| event.address.update(neighbourhood: @ward) }

    # Assign the regional site to have, a region containing the ward, as a neighbourhood
    @regional_neighbourhood_site.neighbourhoods << @ward.region
  end

  test 'default site index page shows all events that are on today and local info' do
    get events_url
    assert_response :success
    assert_select 'title', count: 1, text: "Events & activities in your area | #{@default_site.name}"
    assert_select 'div.hero h4', text: 'The Community Calendar'
    assert_select 'div.hero h1', text: 'Events & activities in your area'
    assert_select 'ol article', @default_site_events.length
  end

  test 'neighbourhood site index page shows all events that are on today and local info' do
    get "http://#{@neighbourhood_site.slug}.lvh.me/events"
    assert_response :success
    assert_select 'title', count: 1, text: "Events & activities in your area | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Events & activities in your area'
    assert_select 'ol article', @neighbourhood_site_events.length
  end

  test 'regional site index page shows all events that are on today and local info' do
    get "http://#{@regional_neighbourhood_site.slug}.lvh.me/events"
    assert_response :success
    assert_select 'title', count: 1, text: "Events & activities in your area | #{@regional_neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Events & activities in your area'
    assert_select 'ol article', @regional_ward_events.length
  end
end
