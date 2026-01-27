# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventsQuery do
  let(:site) { create(:ashdale_site) }
  let(:today) { Time.zone.today }

  describe "#call with period: 'future'" do
    context "when there are fewer events than the limit" do
      before do
        partner = create(:partner)
        partner.service_areas << create(:service_area, neighbourhood: site.primary_neighbourhood)
        create_list(:future_event, 10, partner: partner)
      end

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

    context "when there are more events than the limit" do
      before do
        partner = create(:partner)
        partner.service_areas << create(:service_area, neighbourhood: site.primary_neighbourhood)
        # Create more than FUTURE_LIMIT events
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
  end

  describe "#call with period: 'day'" do
    it "does not truncate results" do
      query = described_class.new(site: site, day: today)
      query.call(period: "day")
      expect(query.truncated).to be false
    end
  end

  describe "#call with period: 'week'" do
    it "does not truncate results" do
      query = described_class.new(site: site, day: today)
      query.call(period: "week")
      expect(query.truncated).to be false
    end
  end
end
