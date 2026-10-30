# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL Events", type: :request do
  let(:partner) { create(:riverside_partner) }
  let(:address) { partner.address }

  def execute_query(query_string, variables: {})
    post "/api/v1/graphql", params: { query: query_string, variables: variables.to_json }
    response.parsed_body
  end

  describe "eventConnection query" do
    before do
      create_list(:event, 5,
                  organiser: partner,
                  dtstart: Time.current,
                  address:)
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

    it "returns events with pagination" do
      result = execute_query(query)

      expect(result["errors"]).to be_nil
      expect(result["data"]["eventConnection"]["edges"].length).to eq(5)
    end

    it "leaves out events whose organiser is hidden" do
      hidden_partner = create(:partner, hidden: true, hidden_reason: "Test", hidden_blame_id: 1)
      create(:event, organiser: hidden_partner, summary: "Hidden Event", dtstart: Time.current, address:)

      summaries = execute_query(query)["data"]["eventConnection"]["edges"].map { |edge| edge["node"]["summary"] }

      expect(summaries.length).to eq(5)
      expect(summaries).not_to include("Hidden Event")
    end

    it "includes event details" do
      result = execute_query(query)

      edges = result["data"]["eventConnection"]["edges"]
      node = edges.first["node"]

      expect(node["id"]).to be_present
      expect(node["summary"]).to be_present
    end
  end

  describe "event query" do
    let!(:event) do
      create(:event,
             organiser: partner,
             summary: "Test Event Summary",
             description: "Detailed description of the event",
             dtstart: Time.current,
             address:)
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

    it "returns a specific event by ID" do
      result = execute_query(query, variables: { id: event.id })

      expect(result["errors"]).to be_nil
      expect(result["data"]["event"]["id"]).to eq(event.id.to_s)
      expect(result["data"]["event"]["summary"]).to eq("Test Event Summary")
    end

    it "includes address information" do
      result = execute_query(query, variables: { id: event.id })

      event_data = result["data"]["event"]
      expect(event_data["address"]["streetAddress"]).to be_present
      expect(event_data["address"]["postalCode"]).to eq(address.postcode)
    end

    it "includes organizer (partner) information" do
      result = execute_query(query, variables: { id: event.id })

      organizer = result["data"]["event"]["organizer"]
      expect(organizer["id"]).to eq(partner.id.to_s)
      expect(organizer["name"]).to eq(partner.name)
    end

    it "returns error for non-existent event" do
      result = execute_query(query, variables: { id: 999_999 })

      # GraphQL returns error when record not found
      expect(result["errors"]).to be_present
    end

    it "treats an event whose organiser is hidden as not found" do
      hidden_partner = create(:partner, hidden: true, hidden_reason: "Test", hidden_blame_id: 1)
      hidden_event = create(:event, organiser: hidden_partner, summary: "Hidden Event", dtstart: Time.current, address:)

      result = execute_query(query, variables: { id: hidden_event.id })

      missing = execute_query(query, variables: { id: 999_999 })
      expect(result["data"]).to be_nil
      expect(result["errors"].sole["message"]).to eq(missing["errors"].sole["message"].sub("999999", hidden_event.id.to_s))
      expect(result.to_json).not_to include("Hidden Event", "NOT EXISTS")
    end
  end

  describe "eventsByFilter query" do
    let(:site) { create(:site) }
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
    let(:ward) { create(:riverside_ward) }

    before do
      site.neighbourhoods << ward
      create_list(:event, 3,
                  organiser: partner,
                  dtstart: 1.day.from_now,
                  address:)
    end

    it "returns events within date range" do
      # Format required: "YYYY-MM-DD HH:MM"
      from_date = Date.current.strftime("%Y-%m-%d 00:00")
      to_date = 7.days.from_now.to_date.strftime("%Y-%m-%d 23:59")

      result = execute_query(query, variables: {
                               fromDate: from_date,
                               toDate: to_date
                             })

      expect(result["errors"]).to be_nil
      expect(result["data"]["eventsByFilter"]).to be_an(Array)
    end

    it "reports dates in the wrong format or order" do
      errors = [
        { fromDate: "next week" },
        { toDate: "2022-11-08" },
        { fromDate: "2022-11-10 09:00", toDate: "2022-11-09 09:00" }
      ].map { |variables| execute_query(query, variables:)["errors"].sole["message"] }

      expect(errors).to eq(["fromDate not in 'YYYY-MM-DD HH:MM' format", "toDate not in 'YYYY-MM-DD HH:MM' format", "toDate is before fromDate"])
    end

    it "returns at most the documented number of events, soonest first" do
      stub_const("Types::EventQueries::EVENTS_BY_FILTER_LIMIT", 2)
      soonest = create(:event, organiser: partner, dtstart: 1.hour.from_now, address:)

      events = execute_query(query)["data"]["eventsByFilter"]

      expect(events.length).to eq(2)
      expect(events.first["id"]).to eq(soonest.id.to_s)
    end

    it "states the maximum in the field description" do
      expect(PlaceCalSchema.query.get_field("eventsByFilter").description).to include("at most 1000 events")
    end

    it "accepts a fromDate up to a year before today" do
      past_event = create(:event, organiser: partner, dtstart: 11.months.ago, address:)

      result = execute_query(query, variables: { fromDate: 1.year.ago.strftime("%Y-%m-%d 00:00") })

      expect(result["errors"]).to be_nil
      expect(result["data"]["eventsByFilter"].pluck("id")).to include(past_event.id.to_s)
    end

    it "rejects a fromDate more than a year before today" do
      create(:event, organiser: partner, dtstart: 5.years.ago, address:)

      result = execute_query(query, variables: { fromDate: "1970-01-01 00:00" })

      expect(result["data"]["eventsByFilter"]).to be_nil
      expect(result["errors"].sole["message"]).to eq("fromDate is more than a year before today")
    end
  end

  describe "eventsByFilter by place and keyword" do
    let(:query) do
      <<-GRAPHQL
        query($place: String, $query: String) {
          eventsByFilter(place: $place, query: $query) { summary url }
        }
      GRAPHQL
    end

    it "finds events by place name and text, and explains an unknown place" do
      address = create(:address, neighbourhood: create(:riverside_ward))
      repair = create(:event, summary: "Repair cafe", address:)
      create(:event, summary: "Choir", address:)

      result = execute_query(query, variables: { place: "Riverside", query: "repair" })
      expect(result["data"]["eventsByFilter"]).to eq([{ "summary" => "Repair cafe", "url" => repair.permalink }])

      error = execute_query(query, variables: { place: "Atlantis" })["errors"].first["message"]
      expect(error).to include("No PlaceCal area called Atlantis")
    end
  end

  describe "eventsByFilter with neighbourhood scope" do
    let(:neighbourhood1) { create(:riverside_ward) }
    let(:query) do
      <<-GRAPHQL
        query($neighbourhoodId: Int) {
          eventsByFilter(neighbourhoodId: $neighbourhoodId) {
            id
            name
          }
        }
      GRAPHQL
    end
    let(:neighbourhood2) { create(:oldtown_ward) }

    let(:address1) { create(:address, neighbourhood: neighbourhood1) }
    let(:address2) { create(:address, neighbourhood: neighbourhood2) }

    let(:partner1) { create(:partner, address: address1) }
    let(:partner2) { create(:partner, address: address2) }

    before do
      create_list(:event, 3, organiser: partner1, dtstart: 1.hour.from_now, address: address1)
      create_list(:event, 5, organiser: partner2, dtstart: 1.hour.from_now, address: address2)
    end

    it "filters events by neighbourhood" do
      result = execute_query(query, variables: { neighbourhoodId: neighbourhood2.id })

      expect(result["errors"]).to be_nil
      events = result["data"]["eventsByFilter"]
      expect(events.length).to eq(5)
    end
  end

  describe "eventsByFilter with tag scope" do
    let(:blue_tag) { create(:tag, name: "Blue") }
    let(:query) do
      <<-GRAPHQL
        query($tagId: Int) {
          eventsByFilter(tagId: $tagId) {
            id
            name
          }
        }
      GRAPHQL
    end
    let(:red_tag) { create(:tag, name: "Red") }

    let(:blue_partner) { create(:partner) }
    let(:red_partner) { create(:partner) }

    before do
      blue_partner.tags << blue_tag
      red_partner.tags << red_tag

      create_list(:event, 6, organiser: blue_partner, dtstart: 1.hour.from_now, address: blue_partner.address)
      create_list(:event, 2, organiser: red_partner, dtstart: 1.hour.from_now, address: red_partner.address)
    end

    it "filters events by partner tag" do
      result = execute_query(query, variables: { tagId: blue_tag.id })

      expect(result["errors"]).to be_nil
      events = result["data"]["eventsByFilter"]
      expect(events.length).to eq(6)
    end
  end

  describe "event geo location" do
    let!(:event) do
      create(:event,
             organiser: partner,
             dtstart: Time.current,
             address: create(:address, latitude: 53.4808, longitude: -2.2426))
    end

    let(:query) do
      <<-GRAPHQL
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
    end

    it "includes geo coordinates" do
      result = execute_query(query)

      expect(result["errors"]).to be_nil
      edges = result["data"]["eventConnection"]["edges"]
      expect(edges.length).to eq(1)

      geo = edges.first["node"]["address"]["geo"]
      expect(geo["latitude"]).to be_present
      expect(geo["longitude"]).to be_present
    end
  end

  describe "online event details" do
    let!(:online_address) { OnlineAddress.create!(url: "https://zoom.us/j/123456", link_type: "direct") }
    let!(:online_event) do
      create(:event, organiser: partner, dtstart: Time.current, address:, online_address:)
    end

    let(:query) do
      <<-GRAPHQL
        query($id: ID!) {
          event(id: $id) {
            id
            onlineEventUrl
            onlineEventUrlType
          }
        }
      GRAPHQL
    end

    it "includes online event URL and type" do
      result = execute_query(query, variables: { id: online_event.id })

      expect(result["errors"]).to be_nil
      node = result["data"]["event"]
      expect(node["onlineEventUrl"]).to eq("https://zoom.us/j/123456")
      expect(node["onlineEventUrlType"]).to eq("direct")
    end
  end
end
