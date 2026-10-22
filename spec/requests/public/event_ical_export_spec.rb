# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Event iCal export", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:partner) { create(:riverside_partner) }
  let(:calendar) { create(:calendar, organiser: partner) }

  before do
    site.neighbourhoods << partner.address.neighbourhood
  end

  def feed_uids(url)
    get url
    expect(response).to be_successful
    Icalendar::Calendar.parse(response.body).first.events.map { |event| event.uid.to_s }
  end

  describe "expanded recurring events" do
    let!(:events) do
      Array.new(2) do |n|
        create(:recurring_event, organiser: partner, calendar:, address: partner.address,
                                 uid: "recurring-series@example.com",
                                 dtstart: (n + 1).weeks.from_now,
                                 dtend: (n + 1).weeks.from_now + 1.hour)
      end
    end
    let(:expected_uids) { events.map { |event| "event-#{event.id}@placecal.org" } }
    let(:partner_feed_url) { partner_url(partner, host: "lvh.me", format: :ics) }

    it "exports a distinct PlaceCal UID for each occurrence" do
      expect(feed_uids(partner_feed_url)).to match_array(expected_uids)
    end

    it "keeps the same UIDs across downloads, feeds and hosts" do
      2.times do
        expect(feed_uids(partner_feed_url)).to match_array(expected_uids)
      end

      ["lvh.me", "#{site.slug}.lvh.me"].each do |host|
        expect(feed_uids(partner_url(partner, host:, format: :ics))).to match_array(expected_uids)
        expect(feed_uids(events_url(host:, format: :ics))).to match_array(expected_uids)

        events.each do |event|
          expect(feed_uids(event_url(event, host:, format: :ics))).to eq(["event-#{event.id}@placecal.org"])
        end
      end
    end

    it "leaves the imported UIDs unchanged in the database" do
      feed_uids(partner_feed_url)

      expect(events.map { |event| event.reload.uid }).to eq(["recurring-series@example.com"] * 2)
    end
  end

  [nil, ""].each do |source_uid|
    context "with a #{source_uid.inspect} source UID" do
      let!(:event) { create(:event, organiser: partner, calendar:, uid: source_uid) }

      it "exports the PlaceCal UID" do
        expect(feed_uids(partner_url(partner, host: "lvh.me", format: :ics)))
          .to eq(["event-#{event.id}@placecal.org"])
      end
    end
  end
end
