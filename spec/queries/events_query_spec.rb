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
      before { create_list(:future_event, 10, partner: partner) }

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
          create(:future_event, partner: partner, dtstart: (i + 1).days.from_now)
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
      before { create(:today_event, partner: partner) }

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
        create(:future_event, partner: partner, dtstart: 2.days.from_now)
        create(:future_event, partner: partner, dtstart: 5.days.from_now)
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
      let!(:one_off_event) { create(:future_event, partner: partner, rrule: nil) }
      let!(:recurring_event) { create(:recurring_event, partner: partner, dtstart: 2.days.from_now) }

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
        create(:future_event, partner: partner, summary: "Zebra event", dtstart: 1.day.from_now)
        create(:future_event, partner: partner, summary: "Apple event", dtstart: 2.days.from_now)
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
      let!(:event1) { create(:future_event, partner: partner) }
      let!(:event2) { create(:future_event, partner: other_partner) }

      context "with partner filter" do
        it "returns only events from the specified partner" do
          query = described_class.new(site: site, day: today)
          result = query.call(period: "future", partner: partner)
          events = result.values.flatten
          expect(events).to include(event1)
          expect(events).not_to include(event2)
        end
      end
    end
  end

  describe "#future_count" do
    before { create_list(:future_event, 5, partner: partner) }

    it "returns the count of future events" do
      query = described_class.new(site: site, day: today)
      expect(query.future_count).to eq(5)
    end
  end

  describe "#next_7_days_count" do
    before do
      create(:future_event, partner: partner, dtstart: 2.days.from_now)
      create(:future_event, partner: partner, dtstart: 5.days.from_now)
      create(:future_event, partner: partner, dtstart: 10.days.from_now)
    end

    it "returns the count of events in the next 7 days" do
      query = described_class.new(site: site, day: today)
      expect(query.next_7_days_count).to eq(2)
    end
  end

  describe "#next_event_after" do
    let!(:event1) { create(:future_event, partner: partner, dtstart: 3.days.from_now) }
    let!(:event2) { create(:future_event, partner: partner, dtstart: 5.days.from_now) }

    it "returns the next event after the given day" do
      query = described_class.new(site: site, day: today)
      expect(query.next_event_after(today)).to eq(event1)
    end

    it "returns nil when no events exist after the given day" do
      query = described_class.new(site: site, day: today)
      expect(query.next_event_after(10.days.from_now)).to be_nil
    end
  end
end
