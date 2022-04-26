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
    (0...5).collect do |n|
      @partner.events.create!(
        dtstart: Time.now,
        summary: "An event summary #{n}",
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end

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

    data = result['data']

    assert data.has_key?('eventConnection'), 'result is missing key `eventConnection`'
    connection = data['eventConnection']

    assert connection.has_key?('edges')
    edges = connection['edges']

    assert edges.length == 5
    # TODO: Actually test that the events we are getting back are the ones we want
  end

  test 'can show specific event' do
    event = @partner.events.create!(
      dtstart: Time.now,
      summary: "An event summary",
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
      time += 1.days
    end

    # events in the near future
    time = now_time + 1.days
    5.times do
      @partner.events.create!(
        dtstart: time,
        summary: 'present: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
      time += 1.days
    end

    # events in the far future
    time = now_time + 100.days
    5.times do
      @partner.events.create!(
        dtstart: time,
        summary: "future: An event summary",
        description: 'Longer text covering the event in more detail',
        address: @address
      )
      time += 1.days
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
      assert_equal events.length, 10, 'was expecting only events in the future'
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
      assert_equal events.length, 15, 'was expecting to see all events'
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
      assert_equal events.length, 5, 'was expecting to see only some future events'
      # TODO: Actually test that the events we are getting back are the ones we want
    end
  end

  # this should mainly be tested elsewhere
  #   (the same place service area scoping is tested)
  test 'can scope to neighbourhood (via partner address)' do
    3.times do
      @partner.events.create!(
        dtstart: DateTime.now + 1.hours,
        summary: "partner 1: An event summary",
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end

    other_address = create(:bare_address_2, neighbourhood: neighbourhoods(:two))
    other_partner = create(:moss_side_partner, address: other_address)

    5.times do
      other_partner.events.create!(
        dtstart: DateTime.now + 1.hours,
        summary: "partner 2: An event summary",
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
    assert_equal events.length, 5, 'was expecting to see only events from other_partner'
    # TODO: Actually test that the events we are getting back are the ones we want
  end

  test 'can scope to neighbourhood (via partner service area)' do
    neighbourhood_good = neighbourhoods(:one)
    neighbourhood_bad  = neighbourhoods(:two)

    @partner.service_areas.create! neighbourhood: neighbourhood_good
    @partner.update! address: nil

    5.times do
      @partner.events.create!(
        dtstart: DateTime.now + 1.hours,
        summary: "partner in good neighbourhood: An event summary",
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end

    other_partner = FactoryBot.build(:moss_side_partner, address: nil)
    other_partner.service_areas.build neighbourhood: neighbourhood_bad
    other_partner.save!

    3.times do
      other_partner.events.create!(
        dtstart: DateTime.now + 1.hours,
        summary: "partner in bad neighbourhood: An event summary",
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
    assert_equal events.length, 5, 'was expecting to see only events within neighbourhood_good service area'
    # TODO: Actually test that the events we are getting back are the ones we want
  end

  # this should mainly be tested elsewhere
  test 'can scope to tag (via partner tags)' do
    have_tag = create(:tag)
    have_not_tag = create(:tag)

    @partner.tags << have_not_tag

    2.times do
      @partner.events.create!(
        dtstart: DateTime.now + 1.hours,
        summary: 'partner 1: An event summary',
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end

    other_address = create(:bare_address_2, neighbourhood: neighbourhoods(:two))
    other_partner = create(:moss_side_partner,
                           address: other_address,
                           tags: [have_tag])

    6.times do
      other_partner.events.create!(
        dtstart: DateTime.now + 1.hours,
        summary: 'partner 2: An event summary',
        description: 'Longer text covering the event in more detail',
        address: other_address
      )
    end

    query_string = <<-GRAPHQL
    query {
      eventsByFilter(tagId: #{have_tag.id}) {
        id
        name
      }
    }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute_field result, 'errors'

    data = assert_field result, 'data'
    events = assert_field data, 'eventsByFilter'
    assert_equal events.length, 6, 'was expecting to see only events from have_tag'
    # TODO: Actually test that the events we are getting back are the ones we want
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

    assert_equal edges.length, 1
    data_event = assert_field edges.first, 'node'

    assert_field_equals data_event, 'id', value: event.id.to_s
    address = assert_field data_event, 'address'
    geo = assert_field address, 'geo'
    assert_field_equals geo, 'longitude', value: event.address.longitude.to_s
    assert_field_equals geo, 'latitude', value: event.address.latitude.to_s
  end
end
