# frozen_string_literal: true

require 'test_helper'

class GraphQLEventTest < ActionDispatch::IntegrationTest

  setup do
    partner_address = FactoryBot.create(:bare_address_1, neighbourhood: neighbourhoods(:one))
    @partner = FactoryBot.create(:partner, address: partner_address)

    @address = @partner.address
    assert @address, 'Failed to create Address from partner'

    @calendar = FactoryBot.create(
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
    # puts JSON.pretty_generate(result.as_json)
    data = result['data']

    assert data.has_key?('eventConnection'), 'result is missing key `eventConnection`'
    connection = data['eventConnection']

    assert connection.has_key?('edges')
    edges = connection['edges']

    assert edges.length == 5
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
    assert result.has_key?('errors') == false, 'errors are present'

    data = result['data']
    assert data.has_key?('event'), 'Data structure does not contain event key'

    data_event = data['event']

    assert data_event['summary'] == event.summary
    assert data_event['name'] == event.summary

    assert data_event.has_key?('startDate'), 'missing startDate'
    assert data_event['startDate'] =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/, 'startDate is not in ISO format'

    assert data_event.has_key?('endDate'), 'missing endDate'
    assert data_event.has_key?('address'), 'missing address'
    assert data_event.has_key?('organizer'), 'missing organizer'
  end

  # the filter tests

  def build_time_events(now_time)

    # events in the past
    time = now_time - 100.days
    5.times do
      @partner.events.create!(
        dtstart: time,
        summary: "past: An event summary",
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
        summary: "present: An event summary",
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
      assert result.has_key?('errors') == false, 'errors are present'

      data = result['data']
      assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

      events = data['eventsByFilter']
      assert events.length == 10, 'was expecting only events in the future'
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
      assert result.has_key?('errors') == false, 'errors are present'

      data = result['data']
      assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

      events = data['eventsByFilter']
      assert events.length == 15, 'was expecting to see all events'
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
      assert result.has_key?('errors') == false, 'errors are present'

      data = result['data']
      assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

      events = data['eventsByFilter']
      assert events.length == 5, 'was expecting to see only some future events'
    end
  end

  # this should mainly be tested elsewhere
  #   (the same place service area scoping is tested)
  test 'can scope to neighbourhood (via partner address)' do

    3.times do
      @partner.events.create!(
        dtstart: Date.today,
        summary: "partner 1: An event summary",
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end


    other_address = FactoryBot.create(:bare_address_2, neighbourhood: neighbourhoods(:two))
    other_partner = FactoryBot.create(:moss_side_partner, address: other_address)

    5.times do
      other_partner.events.create!(
        dtstart: Date.today,
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
    # puts JSON.pretty_generate(result.as_json)
    assert result.has_key?('errors') == false, 'errors are present'

    data = result['data']
    assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

    events = data['eventsByFilter']
    assert events.length == 5, 'was expecting to see only events from other_partner'
  end

  test 'can scope to neighbourhood (via partner service area)' do

    neighbourhood_good = neighbourhoods(:one)
    neighbourhood_bad  = neighbourhoods(:two)

    @partner.service_areas.create! neighbourhood: neighbourhood_good
    @partner.update! address: nil

    5.times do
      @partner.events.create!(
        dtstart: Date.today,
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
        dtstart: Date.today,
        summary: "partner in bad neighbourhood: An event summary",
        description: 'Longer text covering the event in more detail',
        address: FactoryBot.create(:bare_address_2)
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
    # puts JSON.pretty_generate(result.as_json)
    assert result.has_key?('errors') == false, 'errors are present'

    data = result['data']
    assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

    events = data['eventsByFilter']
    assert events.length == 5, 'was expecting to see only events within neighbourhood_good service area'
  end
  # this should mainly be tested elsewhere
  test 'can scope to tag (via partner tags)' do

    have_tag = FactoryBot.create(:tag)
    have_not_tag = FactoryBot.create(:tag)

    @partner.tags << have_not_tag

    2.times do
      @partner.events.create!(
        dtstart: Date.today,
        summary: "partner 1: An event summary",
        description: 'Longer text covering the event in more detail',
        address: @address
      )
    end


    other_address = FactoryBot.create(:bare_address_2, neighbourhood: neighbourhoods(:two))
    other_partner = FactoryBot.create(:moss_side_partner, address: other_address)

    other_partner.tags << have_tag

    6.times do
      other_partner.events.create!(
        dtstart: Date.today,
        summary: "partner 2: An event summary",
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
    # puts JSON.pretty_generate(result.as_json)
    assert result.has_key?('errors') == false, 'errors are present'

    data = result['data']
    assert data.has_key?('eventsByFilter'), 'Data structure does not contain event key'

    events = data['eventsByFilter']
    assert events.length == 6, 'was expecting to see only events from have_tag'
  end
end
