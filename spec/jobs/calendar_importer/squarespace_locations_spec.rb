# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "with Squarespace event locations" do
  let(:url) { "https://example.squarespace.com/events" }
  let(:default_place) { create(:partner, name: "Default Venue") }
  let!(:venue) { create(:partner, name: "Oldtown Community Hall", address: create(:oldtown_address), can_be_assigned_events: true) }
  let(:calendar) { create(:calendar, source: url, importer_mode: "squarespace", place: default_place) }

  let(:full_venue_title) { "TRANSMISSIONS presents THE BIG CITY: Closer (2005)" }
  let(:no_postcode_title) { "TRANSMISSIONS presents THE BIG CITY: Victoria (2015)" }
  let(:blank_title) { "TRANSMISSIONS presents THE BIG CITY: 120 BPM (2017)" }
  let(:no_postcode_notice) do
    I18n.t("admin.calendars.importer.unreadable_address.no_postcode",
           count: 1,
           examples: %("#{no_postcode_title}" (The Reading Room, 4 Mill Lane, Millbrook)))
  end

  before do
    stub_request(:get, url).to_return(status: 200, body: "<html><!-- This is Squarespace. --></html>")
    stub_request(:get, "#{url}?format=json")
      .to_return(status: 200, body: file_fixture("squarespace_events_with_locations.json").read, headers: { "Content-Type" => "application/json" })
  end

  def import(strategy)
    calendar.update!(strategy:, calendar_state: "in_worker")
    described_class.new(calendar, Time.zone.today, true).run
    calendar.reload
  end

  def imported(title)
    calendar.events.find_by!(summary: title)
  end

  shared_examples "a Squarespace venue with a postcode" do |strategy|
    it "gives the event an address and matches it to the partner at that venue", :aggregate_failures do
      import(strategy)
      event = imported(full_venue_title)

      expect(event.raw_location_from_source).to eq("Oldtown Community Hall, 10 Heritage Lane, Millbrook, ZZMB 2OT")
      expect(event.place).to eq(venue)
      expect(event.address).to have_attributes(street_address: "Oldtown Community Hall", street_address2: "10 Heritage Lane",
                                               street_address3: nil, city: "Millbrook", postcode: "ZZMB 2OT")
    end

    it "gives the event an address with no venue when no partner is there", :aggregate_failures do
      venue.update!(name: "Somewhere Else")
      import(strategy)
      event = imported(full_venue_title)

      expect(event.place).to be_nil
      expect(event.address).to have_attributes(street_address: "Oldtown Community Hall", postcode: "ZZMB 2OT")
    end
  end

  describe "event strategy" do
    it_behaves_like "a Squarespace venue with a postcode", "event"

    it "imports all three events" do
      import("event")

      expect(calendar.events.pluck(:summary)).to contain_exactly(full_venue_title, no_postcode_title, blank_title)
    end

    it "gives a venue with no postcode no address or place, and says why", :aggregate_failures do
      import("event")
      event = imported(no_postcode_title)

      expect(event.raw_location_from_source).to eq("The Reading Room, 4 Mill Lane, Millbrook")
      expect(event.address).to be_nil
      expect(event.place).to be_nil
      expect(calendar.notices).to contain_exactly(no_postcode_notice)
    end

    it "places an event with blank address fields at the default venue", :aggregate_failures do
      import("event")
      event = imported(blank_title)

      expect(event.raw_location_from_source).to be_nil
      expect(event.place).to eq(default_place)
      expect(event.address).to be_nil
    end
  end

  describe "event_override strategy" do
    it_behaves_like "a Squarespace venue with a postcode", "event_override"

    it "places a venue with no postcode at the default venue, and says why", :aggregate_failures do
      import("event_override")
      event = imported(no_postcode_title)

      expect(event.raw_location_from_source).to eq("The Reading Room, 4 Mill Lane, Millbrook")
      expect(event.place).to eq(default_place)
      expect(event.address).to eq(default_place.address)
      expect(calendar.notices).to contain_exactly(no_postcode_notice)
    end

    it "places an event with blank address fields at the default venue", :aggregate_failures do
      import("event_override")
      event = imported(blank_title)

      expect(event.raw_location_from_source).to be_nil
      expect(event.place).to eq(default_place)
      expect(event.address).to eq(default_place.address)
    end
  end
end
