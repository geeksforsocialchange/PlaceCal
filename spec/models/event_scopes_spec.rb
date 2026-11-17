# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, "scopes and validations" do
  describe ".for_neighbourhoods" do
    let(:riverside) { create(:riverside_ward) }
    let(:oldtown) { create(:oldtown_ward) }

    it "finds events whose organiser is based in, or serves, the neighbourhoods, once each" do
      based = create(:event, organiser: create(:partner, address: create(:address, neighbourhood: riverside)))
      serving_partner = create(:partner, address: create(:address, neighbourhood: oldtown))
      create(:service_area, partner: serving_partner, neighbourhood: riverside)
      elsewhere = create(:neighbourhood)
      create(:service_area, partner: serving_partner, neighbourhood: elsewhere)
      serving = create(:event, organiser: serving_partner)
      create(:event, organiser: create(:partner, address: create(:address, neighbourhood: oldtown)))

      expect(described_class.for_neighbourhoods([riverside, elsewhere]).ids).to contain_exactly(based.id, serving.id)
    end
  end

  describe ".with_tags" do
    it "finds events whose organiser has any of the tags" do
      blue = create(:tag, name: "Blue")
      tagged = create(:event, organiser: create(:partner, tags: [blue]))
      create(:event, organiser: create(:partner))

      expect(described_class.with_tags([blue])).to contain_exactly(tagged)
    end
  end

  describe "validations" do
    it "names the source's location when the calendar needs one and none could be found" do
      event = build(:event, calendar: create(:calendar, strategy: "place"), place: nil, address: nil, raw_location_from_source: "Back room")

      expect(event).not_to be_valid
      expect(event.errors[:base]).to include("No place or address could be created or found for the event location: Back room")
    end

    it "names the calendar when the event is a duplicate" do
      existing = create(:event)
      duplicate = build(:event, uid: existing.uid, dtstart: existing.dtstart, summary: existing.summary, calendar: existing.calendar)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base])
        .to include("Unfortunately this event is a duplicate of an existing event for calendar: #{existing.calendar_id} ('#{existing.calendar.name}')")
    end
  end
end
