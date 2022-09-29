# frozen_string_literal: true

require 'test_helper'

class GraphQLEventTest < ActionDispatch::IntegrationTest
  setup do
    partner_address = create(:bare_address_1, neighbourhood: neighbourhoods(:one))
    @partner = create(:partner, address: partner_address)

    @address = @partner.address
    assert @address, 'Failed to create Address from partner'

    @calendar = create(
      :calendar,
      partner: @partner,
      name: 'Partner Calendar',
      source: 'http://example.com'
    )
    assert @calendar, 'Failed to create calendar from partner'
  end

  test 'can show partners (with pagination)' do
    create_list(:event, 5,
                partner: @partner,
                dtstart: Time.now,
                address: @address)

    query_string = <<-GRAPHQL
      query {
        eventConnection {
          edges {
            node {
              id
              summary
              description
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = assert_field result, 'data'
    connection = assert_field data, 'eventConnection'
    edges = assert_field connection, 'edges'

    assert_equal(5, edges.length)
    # TODO: Actually test that the events we are getting back are the ones we want
  end

  test 'can show specific event' do
    event = @partner.events.create!(
      dtstart: Time.now,
      summary: 'An event summary',
      description: 'Longer text covering the event in more detail',
      address: @address
    )

    query_string = <<-GRAPHQL
      query {
        event(id: #{event.id}) {
          id
          name
          summary
          description
          startDate
          endDate
          address {
            streetAddress
            postalCode
            addressLocality
            addressRegion
          }
          organizer {
            id
            name
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = result['data']
    assert_field data, 'event', 'Data structure does not contain event key'

    data_event = data['event']

    assert_field_equals data_event, 'summary', value: event.summary
    assert_field_equals data_event, 'name', value: event.summary

    assert_field data_event, 'startDate', 'missing startDate'
    assert data_event['startDate'] =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/, 'startDate is not in ISO format'

    assert_field data_event, 'endDate', 'missing endDate'
    assert_field data_event, 'address', 'missing address'
    assert_field data_event, 'organizer', 'missing organizer'
  end

  # the filter tests

  def build_time_events(now_time)
    # events in the past
    time = now_time - 100.days
    5.times do
      @partner.events.create!(
        dtstart: time,
        summary: 'past: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
      time += 1.day
    end

    # events in the near future
    time = now_time + 1.day
    5.times do
      @partner.events.create!(
        dtstart: time,
        summary: 'present: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
      time += 1.day
    end

    # events in the far future
    time = now_time + 100.days
    5.times do
      @partner.events.create!(
        dtstart: time,
        summary: 'future: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
      time += 1.day
    end
  end

  test 'returns events from today' do
    now_time = DateTime.new(1990, 1, 1, 0, 0, 0)
    build_time_events now_time

    DateTime.stub :now, now_time do
      query_string = <<-GRAPHQL
      query {
        eventsByFilter {
          id
          name
          startDate
        }
      }
      GRAPHQL

      result = PlaceCalSchema.execute(query_string)
      refute_field result, 'errors'

      data = result['data']
      assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

      events = data['eventsByFilter']
      assert_equal(10, events.length, 'was expecting only events in the future')
      # TODO: Actually test that the events we are getting back are the ones we want
    end
  end

  test 'returns events from a given point in time' do
    now_time = DateTime.new(1990, 1, 1, 0, 0, 0)
    build_time_events now_time

    DateTime.stub :now, now_time do
      query_string = <<-GRAPHQL
      query {
        eventsByFilter(fromDate: "1985-01-01 00:00") {
          id
          name
          startDate
        }
      }
      GRAPHQL

      result = PlaceCalSchema.execute(query_string)
      refute_field result, 'errors'

      data = result['data']
      assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

      events = data['eventsByFilter']
      assert_equal(15, events.length, 'was expecting to see all events')
      # TODO: Actually test that the events we are getting back are the ones we want
    end
  end

  test 'returns events in a given range when blocked out' do
    now_time = DateTime.new(1990, 1, 1, 0, 0, 0)
    build_time_events now_time

    DateTime.stub :now, now_time do
      query_string = <<-GRAPHQL
      query {
        eventsByFilter(fromDate: "1990-01-01 00:00", toDate: "1990-03-01 00:00") {
          id
          name
          startDate
        }
      }
      GRAPHQL

      result = PlaceCalSchema.execute(query_string)
      refute_field result, 'errors'

      data = result['data']
      assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

      events = data['eventsByFilter']
      assert_equal(5, events.length, 'was expecting to see only some future events')
      # TODO: Actually test that the events we are getting back are the ones we want
    end
  end

  # this should mainly be tested elsewhere
  #   (the same place service area scoping is tested)
  test 'can scope to neighbourhood (via partner address)' do
    3.times do
      @partner.events.create!(
        dtstart: DateTime.now + 1.hour,
        summary: 'partner 1: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end

    other_address = create(:bare_address_2, neighbourhood: neighbourhoods(:two))
    other_partner = create(:moss_side_partner, address: other_address)

    5.times do
      other_partner.events.create!(
        dtstart: DateTime.now + 1.hour,
        summary: 'partner 2: An event summary',
        description: 'Longer text covering the event in more detail',
        address: other_address
      )
    end

    query_string = <<-GRAPHQL
    query {
      eventsByFilter(neighbourhoodId: #{other_address.neighbourhood_id}) {
        id
        name
      }
    }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = result['data']
    assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

    events = data['eventsByFilter']
    assert_equal(5, events.length, 'was expecting to see only events from other_partner')
    # TODO: Actually test that the events we are getting back are the ones we want
  end

  test 'can scope to neighbourhood (via partner service area)' do
    neighbourhood_good = neighbourhoods(:one)
    neighbourhood_bad  = neighbourhoods(:two)

    @partner.service_areas.create! neighbourhood: neighbourhood_good
    @partner.update! address: nil

    5.times do
      @partner.events.create!(
        dtstart: DateTime.now + 1.hour,
        summary: 'partner in good neighbourhood: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end

    other_partner = FactoryBot.build(:moss_side_partner, address: nil)
    other_partner.service_areas.build neighbourhood: neighbourhood_bad
    other_partner.save!

    3.times do
      other_partner.events.create!(
        dtstart: DateTime.now + 1.hour,
        summary: 'partner in bad neighbourhood: An event summary',
        description: 'Longer text covering the event in more detail',
        address: create(:bare_address_2)
      )
    end

    query_string = <<-GRAPHQL
    query {
      eventsByFilter(neighbourhoodId: #{neighbourhood_good.id}) {
        id
        name
      }
    }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = result['data']
    assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

    events = data['eventsByFilter']
    assert_equal(5, events.length, 'was expecting to see only events within neighbourhood_good service area')
    # TODO: Actually test that the events we are getting back are the ones we want
  end

  # in cases where we have eventConnection { edges { node { ... } } }
  def map_edges_to_ids(edges)
    # [{ 'node': { 'id': 23, etc } }, ...] => { '23': { 'id': 23, etc }, ... }
    edges.map { |edge| [edge['node']['id'].to_i, edge['node']] }.to_h
  end

  # in cases where we have eventsByFilter { ... }
  def map_results_to_ids(events)
    # [{ 'id': 23, etc }, ...] => { '23': { 'id': 23, etc }, ... }
    events.index_by { |event| event['id'].to_i }
  end

  # this should mainly be tested elsewhere
  test 'can scope to tag (via partner tags)' do
    blue_tag = create(:tag)
    red_tag = create(:tag)

    # Red Events should not show up in the results
    @partner.tags << red_tag
    _red_events = create_list(:event, 2, address: @address, partner: @partner)

    # Blue events should show up in the results
    blue_address = create(:bare_address_2, neighbourhood: neighbourhoods(:two))
    blue_events = create_list(:event, 6, address: blue_address)
    _blue_partner = create(:moss_side_partner,
                           address: blue_address,
                           events: blue_events,
                           tags: [blue_tag])

    query_string = <<-GRAPHQL
    query {
      eventsByFilter(tagId: #{blue_tag.id}) {
        id
        name
      }
    }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = assert_field result, 'data'
    event_data = assert_field data, 'eventsByFilter'
    assert_equal event_data.length, blue_events.length, 'was expecting to see only events from blue_tag'

    events = map_results_to_ids event_data

    blue_events.each do |blue_event|
      event = events[blue_event.id]
      assert_field_equals event, 'name', value: blue_event.summary
    end
  end

  test 'test that we have geo location' do
    event = create(:event,
                   address: create(:address,
                                   latitude: 69.420666,
                                   longitude: -2.666666))

    query_string = <<-GRAPHQL
      query {
        eventConnection {
          edges {
            node {
              id
              address {
                geo {
                  longitude
                  latitude
                }
              }
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = assert_field result, 'data'
    connection = assert_field data, 'eventConnection'
    edges = assert_field connection, 'edges'

    assert_equal(1, edges.length)
    data_event = assert_field edges.first, 'node'

    assert_field_equals data_event, 'id', value: event.id.to_s
    address = assert_field data_event, 'address'
    geo = assert_field address, 'geo'
    assert_field_equals geo, 'longitude', value: event.address.longitude.to_s
    assert_field_equals geo, 'latitude', value: event.address.latitude.to_s
  end

  test 'has correct details for online event' do
    online_addresses = [
      create(:online_address, url: 'https://zoom.us/j/sdflgkjshfgls', link_type: 'direct'),
      create(:online_address, url: 'https://eventbrite.com/blahblahblah', link_type: 'indirect'),
      nil
    ]
    events = build_list(:event, 3, partner: @partner, dtstart: Time.now, address: @address)

    # splice the lists so we get a reasonable number of events, this also replaces? the `events` list :)
    # stuff off rubocop this is perfectly fine
    events.zip(online_addresses).each do |event, oa|
      event.online_address = oa
      event.save!
    end

    query_string = <<-GRAPHQL
      query {
        eventConnection {
          edges {
            node {
              id
              onlineEventUrl
              onlineEventUrlType
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = assert_field result, 'data'
    connection = assert_field data, 'eventConnection'
    edges = assert_field connection, 'edges'

    assert_equal edges.length, events.length

    nodes = map_edges_to_ids edges

    events.each do |event|
      node = nodes[event.id]
      assert_field_equals node, 'onlineEventUrl', value: event.online_address&.url
      assert_field_equals node, 'onlineEventUrlType', value: event.online_address&.link_type
    end
  end
end
