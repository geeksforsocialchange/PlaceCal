# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GraphQL Events', type: :request do
  let(:partner) { create(:riverside_partner) }
  let(:address) { partner.address }

  def execute_query(query_string, variables: {})
    post '/api/v1/graphql', params: { query: query_string, variables: variables.to_json }
    JSON.parse(response.body)
  end

  describe 'eventConnection query' do
    before do
      create_list(:event, 5,
                  partner: partner,
                  dtstart: Time.current,
                  address: address)
    end

    let(:query) do
      <<-GRAPHQL
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
    end

    it 'returns events with pagination' do
      result = execute_query(query)

      expect(result['errors']).to be_nil
      expect(result['data']['eventConnection']['edges'].length).to eq(5)
    end

    it 'includes event details' do
      result = execute_query(query)

      edges = result['data']['eventConnection']['edges']
      node = edges.first['node']

      expect(node['id']).to be_present
      expect(node['summary']).to be_present
    end
  end

  describe 'event query' do
    let!(:event) do
      create(:event,
             partner: partner,
             summary: 'Test Event Summary',
             description: 'Detailed description of the event',
             dtstart: Time.current,
             address: address)
    end

    let(:query) do
      <<-GRAPHQL
        query($id: ID!) {
          event(id: $id) {
            id
            name
            summary
            description
            startDate
            endDate
            address {
              streetAddress
              postalCode
            }
            organizer {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    it 'returns a specific event by ID' do
      result = execute_query(query, variables: { id: event.id })

      expect(result['errors']).to be_nil
      expect(result['data']['event']['id']).to eq(event.id.to_s)
      expect(result['data']['event']['summary']).to eq('Test Event Summary')
    end

    it 'includes address information' do
      result = execute_query(query, variables: { id: event.id })

      event_data = result['data']['event']
      expect(event_data['address']['streetAddress']).to be_present
      expect(event_data['address']['postalCode']).to eq(address.postcode)
    end

    it 'includes organizer (partner) information' do
      result = execute_query(query, variables: { id: event.id })

      organizer = result['data']['event']['organizer']
      expect(organizer['id']).to eq(partner.id.to_s)
      expect(organizer['name']).to eq(partner.name)
    end

    it 'returns error for non-existent event' do
      result = execute_query(query, variables: { id: 999_999 })

      # GraphQL returns error when record not found
      expect(result['errors']).to be_present
    end
  end

  describe 'eventsByFilter query' do
    let(:site) { create(:site) }
    let(:ward) { create(:riverside_ward) }

    before do
      site.neighbourhoods << ward
      create_list(:event, 3,
                  partner: partner,
                  dtstart: 1.day.from_now,
                  address: address)
    end

    let(:query) do
      <<-GRAPHQL
        query($fromDate: String, $toDate: String) {
          eventsByFilter(fromDate: $fromDate, toDate: $toDate) {
            id
            summary
            startDate
          }
        }
      GRAPHQL
    end

    it 'returns events within date range' do
      # Format required: "YYYY-MM-DD HH:MM"
      from_date = Date.current.strftime('%Y-%m-%d 00:00')
      to_date = 7.days.from_now.to_date.strftime('%Y-%m-%d 23:59')

      result = execute_query(query, variables: {
                               fromDate: from_date,
                               toDate: to_date
                             })

      expect(result['errors']).to be_nil
      expect(result['data']['eventsByFilter']).to be_an(Array)
    end
  end
end
