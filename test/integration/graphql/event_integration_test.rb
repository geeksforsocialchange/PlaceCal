# frozen_string_literal: true

require 'test_helper'

class GraphQLEventTest < ActionDispatch::IntegrationTest

  setup do
    @partner = FactoryBot.create(:partner)

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
          summary
          description
          address {
            streetAddress
            city
            postcode
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)

    data = result['data']
    assert data.has_key?('event'), 'Data structure does not contain event key'

    data_event = data['event']
    assert data_event['summary'] == event.summary
  end
end
