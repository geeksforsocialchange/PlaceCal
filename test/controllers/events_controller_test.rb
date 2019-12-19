# frozen_string_literal: true

require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    neighbourhoods = [ create(:neighbourhood), create(:neighbourhood), create(:neighbourhood) ]
    # Deliberately saving address twice. (create + save) Second time overwrites neighbourhood.
    addresses = neighbourhoods.map {|n| a=create(:address); a.neighbourhood=n; a.save; a}
    date = DateTime.now.beginning_of_day
    @events = addresses.map { |a| e=build(:event); e.address=a; e.dtstart=date; e.dtend=date+1.hour; e.save; e }
    default_site = create_default_site
    default_site.neighbourhoods.append(neighbourhoods)
    default_site.save
    @site = build(:site)
    @site.neighbourhoods.append(neighbourhoods.first)
    @site.neighbourhoods.append(neighbourhoods.second)
    @site.save
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
    assert_response :redirect
  end

  test 'should show event' do
    get event_url(@events[0])
    assert_response :success
  end
end
