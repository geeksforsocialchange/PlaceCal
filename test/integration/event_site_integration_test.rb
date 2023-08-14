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
      dtend: Date.today + 1.hour,
      address: @partner.address
    )

    @event_2 = Event.create!(
      partner: @partner,
      summary: 'A second event',
      dtstart: Date.today,
      dtend: Date.today + 1.hour,
      address: @partner.address
    )
  end

  test 'returns a regular set of events' do
    found = Event.for_site(@site)
    count = found.count
    assert_equal(2, count)
  end

  test 'does not return events outside of address or service area' do
    other_site_neighbourhood = neighbourhoods(:two)
    other_site = create(:site)
    other_site.neighbourhoods << other_site_neighbourhood

    found = Event.for_site(other_site)
    count = found.count
    assert_equal(0, count)
  end

  test 'also returns events with partners that have service areas in the site scope' do
    other_site_neighbourhood = neighbourhoods(:two)
    other_site = create(:site)
    other_site.neighbourhoods << other_site_neighbourhood

    @partner.service_areas.create! neighbourhood: other_site_neighbourhood

    found = Event.for_site(other_site)
    count = found.count
    assert_equal(2, count)
  end
end

class EventsBySiteTagTest < ActionDispatch::IntegrationTest
  test 'filtering events by partner tag' do
    Neighbourhood.destroy_all

    neighbourhood = Neighbourhood.create!(
      name: 'Neighbourhood 1',
      name_abbr: '',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05011368',
      unit_name: 'Hulme',
      release_date: DateTime.new(2023, 7)
    )

    tag = Tag.create!(
      name: 'Tag',
      slug: 'tag',
      description: 'A tag about a thing',
      type: 'Facility'
    )

    tag_site = Site.create!(
      name: 'A site',
      slug: 'a-site',
      description: 'A site about things',
      domain: 'a-site.lvh.me',
      is_published: true
    )
    tag_site.tags << tag
    tag_site.neighbourhoods << neighbourhood

    address = Address.create!(
      street_address: '123 Street',
      postcode: 'M15 5DD'
    )
    assert_equal address.neighbourhood, neighbourhood

    partner_with_tag = Partner.create!(
      name: 'Partner with tag',
      address: address
    )

    # give same tag from site to partner
    partner_with_tag.tags << tag

    partner_without_tag = Partner.create!(
      name: 'Partner without tag',
      address: address
    )

    # visible events
    2.times do |n|
      Event.create!(
        partner: partner_with_tag,
        summary: "Event with tagged partner #{n}",
        dtstart: DateTime.now + 1.hour,
        dtend: DateTime.now + 2.hours,
        address: address
      )
    end

    # hidden events
    3.times do |n|
      Event.create!(
        partner: partner_without_tag,
        summary: "Event without tagged partner #{n}",
        dtstart: DateTime.now + 1.hour,
        dtend: DateTime.now + 2.hours,
        address: address
      )
    end

    get "http://#{tag_site.slug}.lvh.me/events"
    assert_response :success

    assert_select 'ol.events li .event', count: 2
  end
end
