# frozen_string_literal: true

require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Geocoder.configure( timeout: 10 )

    # Choose postcodes in different admin_wards in order to test filtering
    # events by turf.
    locations = [
      [ "M13 9PL", "Hulme" ],
      [ "M14 5RF", "Rusholme" ],
      [ "M14 4ET", "Moss Side" ]
    ]

    # Create an address in each location.
    # Turfs will be automatically created from geolocated addresses.
    addresses = locations.map { |l| a=build(:address); a.postcode=l[0]; a.save; a }

    @events = addresses.map { |a| e=build(:event); e.address=a; e.dtstart=Time.now; e.dtend=Time.now+1; e.save; e }

    @site = create(:site)

    # Create sites_turfs for a *subset* of turfs for the current site.
    addresses[0..1].each { |a| st=build(:sites_turf); st.site=@site; st.turf=a.neighbourhood_turf; st.save }
  end

  test 'should get index without subdomain' do
    get events_url
    assert_response :success
    assert_select "ol.events li", 3
  end

  test 'should get index with configured subdomain' do
    get url_for controller: :events, subdomain: @site.slug
    assert_response :success
    assert_select "ol.events li", 2
  end

  test 'should get index with invalid subdomain' do
    get url_for controller: :events, subdomain: "notaknownsubdomain"
    assert_response :success
    assert_select "ol.events li", 3
  end

  test 'should show event' do
    get event_url(@events[0])
    assert_response :success
  end
end
