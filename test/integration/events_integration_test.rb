# frozen_string_literal: true

require 'test_helper'

class EventsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @default_site = create_default_site
    @neighbourhood_site = create(:site)

    # Create one set of events for the default site
    @default_site_events = create_list :event, 5, dtstart: Time.now + 1.hour
    @default_site_events.each do |event|
      next if @default_site.neighbourhoods.include? event.neighbourhood

      @default_site.neighbourhoods << event.neighbourhood
    end

    # Create another set for the neighbourhood site
    @neighbourhood_site_events = create_list :event, 5, dtstart: Time.now + 1.hour
    @neighbourhood2 = create(:neighbourhood)
    @neighbourhood_site_events.each do |event|
      event.address.neighbourhood = @neighbourhood2
    end
    @neighbourhood_site.neighbourhoods << @neighbourhood2
  end

  test 'default site index page shows all events that are on today' do
    get events_url
    assert_response :success
    assert_select 'title', count: 1, text: "#{@default_site.name} | Events & activities in your area"
    assert_select 'h1', text: 'Events & activities in your area'
    assert_select 'ol article', 5
  end

  test 'neighbourhood site index page shows events from today' do
    get "http://#{@neighbourhood_site.slug}.lvh.me/events"
    assert_response :success
    assert_select 'title', count: 1, text: "#{@neighbourhood_site.name} | Events & activities in your area"
    assert_select 'h1', text: 'Events & activities in your area'
    assert_select 'ol article', 5
  end
end
