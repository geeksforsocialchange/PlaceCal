# frozen_string_literal: true

require 'test_helper'

class EventIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @slugless_site = create_default_site

    @default_site = create(:site)
    @neighbourhood_site = create(:site_local)

    VCR.use_cassette(:import_test_calendar) do
      @calendar = create(:calendar)
      @event = create(:event, calendar: @calendar)
    end
  end

  test 'redirects to find my placecal for a slugless site' do
    get event_url(@event)
    assert_response :redirect
  end

  test 'event show pages have event and local info' do
    get from_site_slug(@default_site, event_path(@event))
    assert_response :success
    assert_select 'title', count: 1, text: "#{@event.summary}, #{@event.date}, #{@event.time} @ #{@event.partner.name} | #{@default_site.name}"
    assert_select 'div.hero h1', text: @event.summary
    assert_select 'div.event__detail', count: 4
    assert_select '[data-controller="leaflet"]', 1
    assert_select 'div.contact_information', text: 'Problem with this listing? Let us know.'
    assert_select "div.contact_information a:match('href', ?)", /mailto/

    get from_site_slug(@neighbourhood_site, event_path(@event))
    get "http://#{@neighbourhood_site.slug}.lvh.me/events/#{@event.id}"
    assert_response :success
    assert_select 'title', count: 1,
                           text: "#{@event.summary}, #{@event.date}, #{@event.time} @ #{@event.partner.name} | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: @event.summary
    assert_select 'div.event__detail', count: 4
    assert_select '[data-controller="leaflet"]', 1
  end

  test 'event show with bad ID is user friendly' do
    get event_url(99_999)
    assert_response :not_found
    assert_select 'h1', text: 'Not found'
    assert_select 'p', text: 'The page you were looking for does not exist'
  end
end
