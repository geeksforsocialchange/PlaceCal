# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::LocationRule do
  let(:hub) { create(:riverside_community_hub) }
  let(:library) { create(:oldtown_library, can_be_assigned_events: false) }
  let(:oak_hall) { "Oak Hall, 5 Elm Street, ZZMB 1RS" }

  def rule(location, default_location: nil, room_number: false, save: true)
    described_class.new(location:, postcode: CalendarImporter::Events::Base.postcode_in(location), default_location:, room_number:, save:)
  end

  def result_of(...)
    rule(...).result
  end

  before { create(:riverside_ward) }

  describe "an event with its own valid address" do
    it "is placed at a partner that matches the address", :aggregate_failures do
      hub
      result = result_of("Riverside Community Hub, 1 River Road, ZZMB 1RS", default_location: library)

      expect(result.place).to eq(hub)
      expect(result.address.street_lines).to eq(["Riverside Community Hub", "1 River Road"])
      expect(result.match).to eq(:matched_venue)
    end

    it "gets no place when no partner matches, even with a default location", :aggregate_failures do
      result = result_of(oak_hall, default_location: library)

      expect(result.place).to be_nil
      expect(result.address.street_lines).to eq(["Oak Hall", "5 Elm Street"])
      expect(result.address.postcode).to eq("ZZMB 1RS")
      expect(result.match).to eq(:event_address)
    end

    it "gets no place without a default location" do
      expect(result_of(oak_hall)).to have_attributes(place: nil, match: :event_address)
    end

    it "is placed at the default location when the address is the default location's building", :aggregate_failures do
      create(:oldtown_ward)
      result = result_of("10 Heritage Lane, Oldtown, ZZMB 2OT", default_location: library)

      expect(result.place).to eq(library)
      expect(result.address).to eq(library.address)
      expect(result.match).to eq(:default_location)
    end
  end

  describe "an event at the default location's building written differently" do
    def venue(name, *lines, **attrs)
      address = create(:address, street_address: lines[0], street_address2: lines[1], street_address3: lines[2], postcode: "ZZMB 2OT")
      create(:partner, name:, address:, can_be_assigned_events: false, **attrs)
    end

    def at_default?(text, default)
      result_of(text, default_location: default) == CalendarImporter::LocationRule::Result.new(place: default, address: default.address, match: :default_location)
    end

    before { create(:oldtown_ward) }

    it "matches a part of the text to the default location's name" do
      expect(at_default?("Oldtown Library, Heritage Lane, ZZMB 2OT", library)).to be(true)
    end

    it "matches a numbered street line written with an abbreviation, case and punctuation", :aggregate_failures do
      default = venue("Caledonian Hall", "86 Caledonian Road")

      expect(at_default?("Back Room, 86 caledonian rd., ZZMB 2OT", default)).to be(true)
      expect(at_default?("Side Door, 86 Caledonian Rd & Mews, ZZMB 2OT", venue("Mews Hall", "86 Caledonian Road and Mews"))).to be(true)
    end

    it "matches a numbered street on the second line of a default stored as name, street and town" do
      default = venue("Moss Side Millennium Powerhouse", "Moss Side Millennium Powerhouse", "140 Raby Street", "Manchester")

      expect(at_default?("Main Hall, 140 Raby St, ZZMB 2OT", default)).to be(true)
    end

    it "never matches on an unnumbered line such as an area or town", :aggregate_failures do
      default = venue("Powerhouse", "Powerhouse Building", "Hulme", "Manchester")

      expect(at_default?("Other Hall, Hulme, ZZMB 2OT", default)).to be(false)
      expect(at_default?("Other Hall, Manchester, ZZMB 2OT", default)).to be(false)
    end

    it "never matches an unnumbered street by line c, though the first line check still matches the same first line", :aggregate_failures do
      default = venue("Oldtown Hall", "Heritage Lane")

      expect(at_default?("Other Hall, Heritage Lane, ZZMB 2OT", default)).to be(false)
      expect(at_default?("Heritage Lane, ZZMB 2OT", default)).to be(true)
    end

    it "needs the same postcode" do
      expect(result_of("Oldtown Library, 5 Elm Street, ZZMB 1RS", default_location: library)).to have_attributes(place: nil, match: :event_address)
    end

    it "matches a hidden default location, or one with event matching on", :aggregate_failures do
      hidden = venue("Hidden Hall", "3 Quiet Lane", hidden: true, hidden_reason: "Test", hidden_blame_id: 1)
      matching = venue("Matching Hall", "4 Quiet Lane", can_be_assigned_events: true)

      expect(at_default?("Hidden Hall, ZZMB 2OT", hidden)).to be(true)
      expect(at_default?("Rear Entrance, 4 Quiet Ln, ZZMB 2OT", matching)).to be(true)
    end

    it "gives the event its own address when the default location has no address" do
      default = build(:partner, name: "Oak Hall", address: nil)

      expect(result_of(oak_hall, default_location: default)).to have_attributes(place: nil, match: :event_address)
    end
  end

  describe "an event without a valid address" do
    it "uses the default location and its address, and says why the text wasn't an address", :aggregate_failures do
      rule = rule("The park by the river", default_location: library)

      expect(rule.result).to have_attributes(place: library, address: library.address, match: :default_location)
      expect(rule.unreadable_address_reason).to eq(:no_postcode)
    end

    it "uses the default location when there is no location text" do
      expect(result_of("", default_location: library)).to have_attributes(place: library, address: library.address, match: :default_location)
    end

    it "has no location without a default location", :aggregate_failures do
      expect(result_of("The park by the river")).to have_attributes(place: nil, address: nil, match: :none)
      expect(result_of(nil)).to have_attributes(place: nil, address: nil, match: :none)
    end

    it "treats a link as no address, without an unreadable address reason", :aggregate_failures do
      rule = rule("https://zoom.example/j/123", default_location: library)

      expect(rule.result).to have_attributes(place: library, address: library.address, match: :default_location)
      expect(rule.unreadable_address_reason).to be_nil
    end

    it "says when the postcode lookup didn't respond" do
      allow(PostcodeLookup).to receive(:call).and_raise(PostcodeLookup::Unavailable)
      rule = rule(oak_hall, default_location: library)

      rule.result

      expect(rule.unreadable_address_reason).to eq(:lookup_unavailable)
    end
  end

  describe "with the room number flag" do
    it "adds the location text as a room on the default location's address", :aggregate_failures do
      result = result_of("Room 4", default_location: hub, room_number: true)

      expect(result.place).to eq(hub)
      expect(result.address.street_lines).to eq(["Room 4", "1 River Road"])
      expect(result.match).to eq(:room)
    end

    it "never reads the location text as an address" do
      result = result_of(oak_hall, default_location: hub, room_number: true)

      expect(result).to have_attributes(place: hub, match: :room)
    end

    it "uses the default location's own address for a link or no text", :aggregate_failures do
      expect(result_of("https://zoom.example/j/123", default_location: hub, room_number: true))
        .to have_attributes(place: hub, address: hub.address, match: :default_location)
      expect(result_of("", default_location: hub, room_number: true)).to have_attributes(place: hub, address: hub.address, match: :default_location)
    end

    it "gives the default location no address when it has none" do
      venue = build(:partner, address: nil)

      expect(result_of("Room 4", default_location: venue, room_number: true)).to have_attributes(place: venue, address: nil, match: :default_location)
    end

    it "is ignored without a default location" do
      expect(result_of(oak_hall, room_number: true)).to have_attributes(place: nil, match: :event_address)
    end
  end

  describe "saving" do
    it "saves the addresses it builds", :aggregate_failures do
      hub
      expect(result_of(oak_hall).address).to be_persisted
      expect(result_of("Room 4", default_location: hub, room_number: true).address).to be_persisted
    end

    it "saves nothing when told not to", :aggregate_failures do
      hub

      expect do
        expect(result_of(oak_hall, save: false).address).to have_attributes(new_record?: true, city: "Millbrook")
        expect(result_of("Room 4", default_location: hub, room_number: true, save: false).address).to be_new_record
      end.not_to change(Address, :count)
    end
  end
end
