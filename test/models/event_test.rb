# frozen_string_literal: true

require 'test_helper'

class EventForSiteScopeTest < ActiveSupport::TestCase
  # context Event#for_site

  setup do
    @neighbourhood = neighbourhoods(:one)
    @site = create(:site)
    @site.neighbourhoods << @neighbourhood

    @partner = create(:partner, address: create(:address, neighbourhood: @neighbourhood))

    @event_1 = Event.create!(
      partner: @partner,
      summary: 'A summary of this event',
      dtstart: Date.today,
      address: @partner.address
    )

    @event_2 = Event.create!(
      partner: @partner,
      summary: 'A second event',
      dtstart: Date.today,
      address: @partner.address
    )
  end

  test "returns a regular set of events" do
    found = Event.for_site(@site)
    count = found.count
    assert count == 2
  end

  test "does not return events outside of address or service area" do
    other_site_neighbourhood = neighbourhoods(:two)
    other_site = create(:site)
    other_site.neighbourhoods << other_site_neighbourhood

    found = Event.for_site(other_site)
    count = found.count
    assert count == 0
  end

  test "also returns events with partners that have service areas in the site scope" do
    other_site_neighbourhood = neighbourhoods(:two)
    other_site = create(:site)
    other_site.neighbourhoods << other_site_neighbourhood

    @partner.service_areas.create! neighbourhood: other_site_neighbourhood

    found = Event.for_site(other_site)
    count = found.count
    assert count == 2
  end

end
