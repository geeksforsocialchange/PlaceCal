# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, type: :model do
  describe "associations" do
    # NOTE: partner association is optional: true but has presence validation
    it { is_expected.to belong_to(:partner).optional(false) }
    it { is_expected.to belong_to(:place).class_name("Partner").optional }
    it { is_expected.to belong_to(:address).optional }
    it { is_expected.to belong_to(:online_address).optional }
    it { is_expected.to belong_to(:calendar).optional }
    it { is_expected.to have_and_belong_to_many(:collections) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_presence_of(:dtstart) }
    it { is_expected.to validate_presence_of(:partner) }
  end

  describe "paper_trail" do
    it "has paper_trail enabled" do
      expect(described_class.new).to respond_to(:versions)
    end
  end

  describe "factories" do
    it "creates a valid event" do
      event = build(:event)
      expect(event).to be_valid
    end

    it "creates a past event" do
      event = build(:past_event)
      expect(event.dtstart).to be < Time.current
    end

    it "creates a future event" do
      event = build(:future_event)
      expect(event.dtstart).to be > Time.current
    end

    it "creates an online event" do
      event = build(:online_event)
      expect(event.online_address).to be_present
    end

    it "creates a hybrid event" do
      event = build(:hybrid_event)
      expect(event.address).to be_present
      expect(event.online_address).to be_present
    end
  end

  describe "scopes" do
    let(:partner) { create(:partner) }

    describe ".find_by_day" do
      let!(:event_today) do
        create(:event,
               partner: partner,
               dtstart: Time.current.beginning_of_day + 10.hours,
               dtend: Time.current.beginning_of_day + 12.hours)
      end
      let!(:event_tomorrow) do
        create(:event,
               partner: partner,
               dtstart: 1.day.from_now.beginning_of_day + 10.hours,
               dtend: 1.day.from_now.beginning_of_day + 12.hours)
      end

      it "returns events on the specified day" do
        result = described_class.find_by_day(Time.current)
        expect(result).to include(event_today)
        expect(result).not_to include(event_tomorrow)
      end
    end

    describe ".find_by_week" do
      let(:this_week_start) { Time.current.beginning_of_week }
      let!(:event_this_week) do
        create(:event,
               partner: partner,
               dtstart: this_week_start + 2.days,
               dtend: this_week_start + 2.days + 2.hours)
      end
      let!(:event_next_week) do
        create(:event,
               partner: partner,
               dtstart: this_week_start + 9.days,
               dtend: this_week_start + 9.days + 2.hours)
      end

      it "returns events in the specified week" do
        result = described_class.find_by_week(Time.current)
        expect(result).to include(event_this_week)
        expect(result).not_to include(event_next_week)
      end
    end

    describe ".future" do
      let!(:past_event) do
        create(:event, partner: partner, dtstart: 1.day.ago, dtend: 1.day.ago + 2.hours)
      end
      let!(:future_event) do
        create(:event, partner: partner, dtstart: 1.day.from_now, dtend: 1.day.from_now + 2.hours)
      end

      it "returns only future events" do
        result = described_class.future(Time.current)
        expect(result).to include(future_event)
        expect(result).not_to include(past_event)
      end
    end

    describe ".for_site" do
      let(:ward) { create(:riverside_ward) }
      let(:site) { create(:site) }
      let(:address) { create(:address, neighbourhood: ward) }
      let(:partner) { create(:partner, address: address) }
      let!(:event1) do
        create(:event,
               partner: partner,
               summary: "Event in site neighbourhood",
               dtstart: 1.hour.from_now,
               dtend: 2.hours.from_now,
               address: address)
      end
      let!(:event2) do
        create(:event,
               partner: partner,
               summary: "Second event in site",
               dtstart: 1.hour.from_now,
               dtend: 2.hours.from_now,
               address: address)
      end

      before do
        site.neighbourhoods << ward
      end

      it "returns events in the site neighbourhood" do
        result = described_class.for_site(site)
        expect(result.count).to eq(2)
        expect(result).to include(event1, event2)
      end

      it "does not return events outside site neighbourhood" do
        other_ward = create(:oldtown_ward)
        other_site = create(:site)
        other_site.neighbourhoods << other_ward

        result = described_class.for_site(other_site)
        expect(result.count).to eq(0)
      end

      it "returns events for partners with service areas in the site scope" do
        other_ward = create(:oldtown_ward)
        other_site = create(:site)
        other_site.neighbourhoods << other_ward

        # Partner adds service area in the other site's neighbourhood
        partner.service_areas.create!(neighbourhood: other_ward)

        result = described_class.for_site(other_site)
        expect(result.count).to eq(2)
      end
    end
  end

  describe "location requirement" do
    let(:partner) { create(:partner) }

    it "requires some form of location when calendar strategy requires it" do
      # Create calendar with 'place' strategy which requires location
      place_calendar = create(:place_calendar, partner: partner)
      event = build(:event, partner: partner, calendar: place_calendar, address: nil, online_address: nil, place: nil)
      event.address = nil
      event.place = nil
      event.online_address = nil
      # The validation will fail if no location is set
      expect(event).not_to be_valid
      expect(event.errors[:base].first).to include("No place or address")
    end

    it "is valid with just an address" do
      event = build(:event, partner: partner, online_address: nil, place: nil)
      expect(event).to be_valid
    end

    it "is valid with just an online address" do
      event = build(:online_event, partner: partner, address: nil, place: nil)
      expect(event).to be_valid
    end

    it "does not require location for event strategy calendar" do
      # Default calendar factory uses 'event' strategy
      event = build(:event, partner: partner, address: nil, online_address: nil)
      event.address = nil
      event.online_address = nil
      expect(event).to be_valid
    end
  end

  describe "html caching" do
    it "caches description HTML" do
      event = build(:event, description: "**bold text**")
      expect(event).to respond_to(:description_html)
    end

    it "caches summary HTML" do
      event = build(:event, summary: "Test Event")
      expect(event).to respond_to(:summary_html)
    end
  end
end
