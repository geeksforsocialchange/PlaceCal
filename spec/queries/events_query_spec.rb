# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventsQuery do
  let(:site) { create(:ashdale_site) }
  let(:today) { Time.zone.today }
  let(:partner) do
    p = create(:partner)
    p.service_areas << create(:service_area, neighbourhood: site.primary_neighbourhood)
    p
  end

  describe "#call" do
    describe "period: 'future' with fewer events than limit" do
      before { create_list(:future_event, 10, organiser: partner) }

      it "returns all events" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future")
        total_events = result.values.flatten.count
        expect(total_events).to eq(10)
      end

      it "sets truncated to false" do
        query = described_class.new(site: site, day: today)
        query.call(period: "future")
        expect(query.truncated).to be false
      end
    end

    describe "period: 'future' with more events than limit" do
      before do
        (described_class::FUTURE_LIMIT + 10).times do |i|
          create(:future_event, organiser: partner, dtstart: (i + 1).days.from_now)
        end
      end

      it "limits results to FUTURE_LIMIT" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future")
        total_events = result.values.flatten.count
        expect(total_events).to eq(described_class::FUTURE_LIMIT)
      end

      it "sets truncated to true" do
        query = described_class.new(site: site, day: today)
        query.call(period: "future")
        expect(query.truncated).to be true
      end
    end

    describe "period: 'day'" do
      before { create(:today_event, organiser: partner) }

      it "returns events for the specified day" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "day")
        expect(result.keys).to eq([today])
      end

      it "does not truncate results" do
        query = described_class.new(site: site, day: today)
        query.call(period: "day")
        expect(query.truncated).to be false
      end
    end

    describe "period: 'week'" do
      before do
        create(:future_event, organiser: partner, dtstart: 2.days.from_now)
        create(:future_event, organiser: partner, dtstart: 5.days.from_now)
      end

      it "returns events within the next 7 days" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "week")
        expect(result.values.flatten.count).to eq(2)
      end

      it "does not truncate results" do
        query = described_class.new(site: site, day: today)
        query.call(period: "week")
        expect(query.truncated).to be false
      end
    end

    describe "repeating filtering" do
      let!(:one_off_event) { create(:future_event, organiser: partner, rrule: nil) }
      let!(:recurring_event) { create(:recurring_event, organiser: partner, dtstart: 2.days.from_now) }

      context "with repeating: 'on' (default)" do
        it "includes all events" do
          query = described_class.new(site: site, day: today)
          result = query.call(period: "future", repeating: "on")
          expect(result.values.flatten.count).to eq(2)
        end
      end

      context "with repeating: 'off'" do
        it "excludes recurring events" do
          query = described_class.new(site: site, day: today)
          result = query.call(period: "future", repeating: "off")
          events = result.values.flatten
          expect(events).to include(one_off_event)
          expect(events).not_to include(recurring_event)
        end
      end
    end

    describe "sort filtering" do
      before do
        create(:future_event, organiser: partner, summary: "Zebra event", dtstart: 1.day.from_now)
        create(:future_event, organiser: partner, summary: "Apple event", dtstart: 2.days.from_now)
      end

      context "with sort: 'time' (default)" do
        it "groups events by date" do
          query = described_class.new(site: site, day: today)
          result = query.call(period: "future", sort: "time")
          expect(result.keys.count).to eq(2)
        end
      end

      context "with sort: 'summary'" do
        it "returns events grouped under today's date" do
          query = described_class.new(site: site, day: today)
          result = query.call(period: "future", sort: "summary")
          expect(result.keys).to eq([today])
        end
      end
    end

    describe "location filtering" do
      let(:other_partner) do
        p = create(:partner)
        p.service_areas << create(:service_area, neighbourhood: site.primary_neighbourhood)
        p
      end
      let!(:event1) { create(:future_event, organiser: partner) }
      let!(:event2) { create(:future_event, organiser: other_partner) }

      context "with partner filter" do
        it "returns only events from the specified partner" do
          query = described_class.new(site: site, day: today)
          result = query.call(period: "future", organiser: partner)
          events = result.values.flatten
          expect(events).to include(event1)
          expect(events).not_to include(event2)
        end
      end
    end
  end

  describe "#future_count" do
    before { create_list(:future_event, 5, organiser: partner) }

    it "returns the count of future events" do
      query = described_class.new(site: site, day: today)
      expect(query.future_count).to eq(5)
    end
  end

  describe "#next_7_days_count" do
    before do
      create(:future_event, organiser: partner, dtstart: 2.days.from_now)
      create(:future_event, organiser: partner, dtstart: 5.days.from_now)
      create(:future_event, organiser: partner, dtstart: 10.days.from_now)
    end

    it "returns the count of events in the next 7 days" do
      query = described_class.new(site: site, day: today)
      expect(query.next_7_days_count).to eq(2)
    end
  end

  describe "#next_event_after" do
    let!(:event1) { create(:future_event, organiser: partner, dtstart: 3.days.from_now) }
    let!(:event2) { create(:future_event, organiser: partner, dtstart: 5.days.from_now) }

    it "returns the next event after the given day" do
      query = described_class.new(site: site, day: today)
      expect(query.next_event_after(today)).to eq(event1)
    end

    it "returns nil when no events exist after the given day" do
      query = described_class.new(site: site, day: today)
      expect(query.next_event_after(10.days.from_now)).to be_nil
    end
  end

  describe "#call with partner_or_place filter" do
    let(:place) { create(:partner) }
    let!(:event_by_partner) { create(:future_event, organiser: partner) }
    let!(:event_at_place) { create(:future_event, organiser: create(:partner), place: partner) }
    let!(:unrelated_event) { create(:future_event, organiser: create(:partner)) }

    it "returns events where partner matches" do
      query = described_class.new(site: nil, day: today)
      result = query.call(period: "future", organiser_or_place: partner)
      events = result.values.flatten

      expect(events).to include(event_by_partner)
    end

    it "returns events where place matches" do
      query = described_class.new(site: nil, day: today)
      result = query.call(period: "future", organiser_or_place: partner)
      events = result.values.flatten

      expect(events).to include(event_at_place)
    end

    it "excludes unrelated events" do
      query = described_class.new(site: nil, day: today)
      result = query.call(period: "future", organiser_or_place: partner)
      events = result.values.flatten

      expect(events).not_to include(unrelated_event)
    end
  end

  describe "#call with limit parameter" do
    before do
      10.times do |i|
        create(:future_event, organiser: partner, dtstart: (i + 1).days.from_now)
      end
    end

    it "limits the number of results" do
      query = described_class.new(site: site, day: today)
      result = query.call(period: "future", limit: 3)
      events = result.values.flatten

      expect(events.count).to eq(3)
    end

    it "returns all events when limit is nil" do
      query = described_class.new(site: site, day: today)
      result = query.call(period: "future", limit: nil)
      events = result.values.flatten

      expect(events.count).to eq(10)
    end
  end

  describe "#call with nil site" do
    let(:standalone_partner) { create(:partner) }
    let!(:event) { create(:future_event, organiser: standalone_partner) }

    it "returns events without site filtering" do
      query = described_class.new(site: nil, day: today)
      result = query.call(period: "future", organiser: standalone_partner)
      events = result.values.flatten

      expect(events).to include(event)
    end
  end

  describe "#for_ical" do
    before { create_list(:future_event, 3, organiser: partner) }

    it "returns events as a relation for ical feed" do
      query = described_class.new(site: site, day: today)
      result = query.for_ical

      expect(result.count).to eq(3)
    end

    it "returns events scoped to site" do
      other_partner = create(:partner)
      create(:future_event, organiser: other_partner)

      query = described_class.new(site: site, day: today)
      result = query.for_ical

      expect(result.count).to eq(3)
    end
  end

  describe "#neighbourhoods_with_counts" do
    context "when site has a district with ward children" do
      let(:district) { site.primary_neighbourhood }
      let(:ward1) { create(:neighbourhood, name: "Hillcrest", unit: "ward", parent: district) }
      let(:ward2) { create(:neighbourhood, name: "Valleyview", unit: "ward", parent: district) }
      let(:address1) { create(:address, neighbourhood: ward1) }
      let(:address2) { create(:address, neighbourhood: ward2) }

      let(:partner1) do
        p = create(:partner, address: address1)
        p.service_areas << create(:service_area, neighbourhood: ward1)
        p
      end

      let(:partner2) do
        p = create(:partner, address: address2)
        p.service_areas << create(:service_area, neighbourhood: ward2)
        p
      end

      before do
        create_list(:future_event, 3, organiser: partner1, address: address1)
        create_list(:future_event, 2, organiser: partner2, address: address2)
      end

      it "shows all descendant neighbourhoods with event counts" do
        query = described_class.new(site: site, day: today)
        result = query.neighbourhoods_with_counts(period: "future")

        ward1_result = result.find { |r| r[:neighbourhood].id == ward1.id }
        ward2_result = result.find { |r| r[:neighbourhood].id == ward2.id }
        expect(ward1_result[:count]).to eq(3)
        expect(ward2_result[:count]).to eq(2)
      end

      it "orders neighbourhoods by name" do
        query = described_class.new(site: site, day: today)
        result = query.neighbourhoods_with_counts(period: "future")

        names = result.map { |r| r[:neighbourhood].name }
        expect(names).to eq(names.sort)
      end
    end

    context "when site has a county with deeper hierarchy" do
      # county → district → wards
      let(:county) { create(:neighbourhood, name: "Coastshire", unit: "county") }
      let(:district) { create(:neighbourhood, name: "Seaview", unit: "district", parent: county) }
      let(:ward1) { create(:neighbourhood, name: "Cliffside", unit: "ward", parent: district) }
      let(:ward2) { create(:neighbourhood, name: "Beachfront", unit: "ward", parent: district) }

      let(:county_site) do
        s = create(:site)
        create(:sites_neighbourhood, site: s, neighbourhood: county)
        s
      end

      let(:address1) { create(:address, neighbourhood: ward1) }
      let(:address2) { create(:address, neighbourhood: ward2) }

      let(:partner1) do
        p = create(:partner, address: address1)
        p.service_areas << create(:service_area, neighbourhood: ward1)
        p
      end

      let(:partner2) do
        p = create(:partner, address: address2)
        p.service_areas << create(:service_area, neighbourhood: ward2)
        p
      end

      before do
        create_list(:future_event, 3, organiser: partner1, address: address1)
        create_list(:future_event, 2, organiser: partner2, address: address2)
      end

      it "shows all levels with subtree counts" do
        query = described_class.new(site: county_site, day: today)
        result = query.neighbourhoods_with_counts(period: "future")

        # Should include district (with sum of all ward events) AND both wards
        district_result = result.find { |r| r[:neighbourhood].id == district.id }
        ward1_result = result.find { |r| r[:neighbourhood].id == ward1.id }
        ward2_result = result.find { |r| r[:neighbourhood].id == ward2.id }

        expect(district_result[:count]).to eq(5)
        expect(ward1_result[:count]).to eq(3)
        expect(ward2_result[:count]).to eq(2)
      end
    end

    context "when site neighbourhood has no children (leaf level)" do
      let(:leaf_site) do
        s = create(:site)
        ward = create(:neighbourhood, name: "Leaf Ward")
        create(:sites_neighbourhood, site: s, neighbourhood: ward)
        s
      end

      before do
        ward = leaf_site.primary_neighbourhood
        address = create(:address, neighbourhood: ward)
        partner_in_ward = create(:partner, address: address)
        partner_in_ward.service_areas << create(:service_area, neighbourhood: ward)
        create_list(:future_event, 3, organiser: partner_in_ward, address: address)
      end

      it "returns empty (no descendants to show)" do
        query = described_class.new(site: leaf_site, day: today)
        result = query.neighbourhoods_with_counts(period: "future")

        expect(result).to be_empty
      end
    end

    context "with period filtering" do
      let(:district) { site.primary_neighbourhood }
      let(:ward) { create(:neighbourhood, name: "Test Ward", unit: "ward", parent: district) }
      let(:address) { create(:address, neighbourhood: ward) }

      let(:partner_in_ward) do
        p = create(:partner, address: address)
        p.service_areas << create(:service_area, neighbourhood: ward)
        p
      end

      before do
        create(:future_event, organiser: partner_in_ward, address: address, dtstart: 2.days.from_now)
        create(:future_event, organiser: partner_in_ward, address: address, dtstart: 10.days.from_now)
      end

      it "counts only events in the specified period" do
        query = described_class.new(site: site, day: today)
        result = query.neighbourhoods_with_counts(period: "week")

        ward_result = result.find { |r| r[:neighbourhood].id == ward.id }
        expect(ward_result[:count]).to eq(1)
      end
    end

    context "with no events" do
      it "returns empty array" do
        query = described_class.new(site: site, day: today)
        result = query.neighbourhoods_with_counts(period: "future")

        expect(result).to be_empty
      end
    end
  end

  describe "#call with neighbourhood_id filter" do
    let(:district) { site.primary_neighbourhood }

    context "filtering by exact neighbourhood" do
      let(:ward1) { create(:neighbourhood, name: "Ward A", unit: "ward", parent: district) }
      let(:ward2) { create(:neighbourhood, name: "Ward B", unit: "ward", parent: district) }
      let(:address1) { create(:address, neighbourhood: ward1) }
      let(:address2) { create(:address, neighbourhood: ward2) }

      let(:partner1) do
        p = create(:partner, address: address1)
        p.service_areas << create(:service_area, neighbourhood: ward1)
        p
      end

      let!(:event_in_ward1) { create(:future_event, organiser: partner1, address: address1) }
      let!(:event_in_ward2) { create(:future_event, organiser: partner1, address: address2) }

      it "includes events with address in the neighbourhood" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: ward1.id)
        events = result.values.flatten

        expect(events).to include(event_in_ward1)
      end

      it "excludes events with address in other neighbourhoods" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: ward1.id)
        events = result.values.flatten

        expect(events).not_to include(event_in_ward2)
      end
    end

    context "filtering by parent neighbourhood includes descendants" do
      let(:ward) { create(:neighbourhood, name: "Child Ward", unit: "ward", parent: district) }
      let(:ward_address) { create(:address, neighbourhood: ward) }

      let(:ward_partner) do
        p = create(:partner, address: ward_address)
        p.service_areas << create(:service_area, neighbourhood: ward)
        p
      end

      let!(:event_in_ward) { create(:future_event, organiser: ward_partner, address: ward_address) }

      it "includes events in child wards when filtering by district" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: district.id)
        events = result.values.flatten

        expect(events).to include(event_in_ward)
      end
    end

    context "filtering by partner's address when event has no address" do
      let(:ward1) { create(:neighbourhood, name: "Ward A", unit: "ward", parent: district) }
      let(:ward2) { create(:neighbourhood, name: "Ward B", unit: "ward", parent: district) }
      let(:address1) { create(:address, neighbourhood: ward1) }
      let(:address2) { create(:address, neighbourhood: ward2) }

      let(:partner_in_ward1) do
        p = create(:partner, address: address1)
        p.service_areas << create(:service_area, neighbourhood: ward1)
        p
      end

      let(:partner_in_ward2) do
        p = create(:partner, address: address2)
        p.service_areas << create(:service_area, neighbourhood: ward2)
        p
      end

      let!(:event_no_address_partner_ward1) { create(:future_event, organiser: partner_in_ward1, address: nil) }
      let!(:event_no_address_partner_ward2) { create(:future_event, organiser: partner_in_ward2, address: nil) }

      it "includes events where partner address is in neighbourhood" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: ward1.id)
        events = result.values.flatten

        expect(events).to include(event_no_address_partner_ward1)
      end

      it "excludes events where partner address is in other neighbourhood" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: ward1.id)
        events = result.values.flatten

        expect(events).not_to include(event_no_address_partner_ward2)
      end
    end

    context "event address takes precedence over partner address" do
      let(:ward1) { create(:neighbourhood, name: "Ward A", unit: "ward", parent: district) }
      let(:ward2) { create(:neighbourhood, name: "Ward B", unit: "ward", parent: district) }
      let(:address1) { create(:address, neighbourhood: ward1) }
      let(:address2) { create(:address, neighbourhood: ward2) }

      let(:partner_in_ward1) do
        p = create(:partner, address: address1)
        p.service_areas << create(:service_area, neighbourhood: ward1)
        p
      end

      # Event is in ward2, but partner's office is in ward1
      let!(:event_in_ward2_partner_in_ward1) { create(:future_event, organiser: partner_in_ward1, address: address2) }

      it "filters by event address, not partner address" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: ward1.id)
        events = result.values.flatten

        # Event should NOT appear when filtering by ward1, because event is physically in ward2
        expect(events).not_to include(event_in_ward2_partner_in_ward1)
      end

      it "shows event when filtering by its actual location" do
        query = described_class.new(site: site, day: today)
        result = query.call(period: "future", neighbourhood_id: ward2.id)
        events = result.values.flatten

        expect(events).to include(event_in_ward2_partner_in_ward1)
      end
    end
  end
end
