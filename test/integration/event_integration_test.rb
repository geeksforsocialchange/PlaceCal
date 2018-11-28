# frozen_string_literal: true

require 'test_helper'

class EventIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @default_site = create_default_site
    @neighbourhood_site = create(:site_local)

    @event = create(:event)
  end

  test 'show pages have event and local info' do
    get event_url(@event)
    assert_response :success
    assert_select 'title', count: 1, text: "#{@default_site.name} | #{@event.summary}, #{@event.date}, #{@event.time}"
    assert_select 'div.hero h4', text: 'The Community Calendar'
    assert_select 'div.hero h1', text: @event.summary
    assert_select 'div.event__detail', count: 4
    assert_select '#js-map', 1

    get "http://#{@neighbourhood_site.slug}.lvh.me/events/#{@event.id}"
    assert_response :success
    assert_select 'title', count: 1, text: "#{@neighbourhood_site.name} | #{@event.summary}, #{@event.date}, #{@event.time}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: @event.summary
    assert_select 'div.event__detail', count: 4
    assert_select '#js-map', 1
  end
end
