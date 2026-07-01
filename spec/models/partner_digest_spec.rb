# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerDigest do
  let(:user) { create(:user) }

  def section_for(partner)
    described_class.new(user).sections.find { |s| s.partner == partner }
  end

  describe "#sections" do
    it "covers all the user's partners, ordered by name" do
      zebra = create(:partner, name: "Zebra Collective")
      apple = create(:partner, name: "Apple Community Group")
      user.partners << [zebra, apple]

      expect(described_class.new(user).sections.map(&:partner)).to eq [apple, zebra]
    end

    it "excludes hidden partners — the digest describes what's published" do
      hidden = create(:partner, hidden: true, hidden_reason: "Moderated", hidden_blame_id: 1)
      user.partners << hidden

      expect(described_class.new(user).sections).to be_empty
    end

    context "with a working feed" do
      let(:partner) { create(:partner) }

      before do
        user.partners << partner
        create(:calendar, organiser: partner).update!(last_import_at: 2.days.ago)
      end

      it "builds a healthy section with the last sync time" do
        section = section_for(partner)

        expect(section).to be_healthy
        expect(section.last_import_at).to be_within(1.minute).of(2.days.ago)
      end

      it "lists the next five upcoming events in date order" do
        7.times do |i|
          create(:event, organiser: partner, dtstart: (7 - i).days.from_now, summary: "Event #{7 - i}")
        end
        create(:event, organiser: partner, dtstart: 1.week.ago) # past, excluded

        section = section_for(partner)

        expect(section.upcoming_events.size).to eq 5
        expect(section.upcoming_events.map(&:dtstart)).to eq section.upcoming_events.map(&:dtstart).sort
      end
    end

    context "with a failing feed" do
      let(:partner) { create(:partner) }

      before { user.partners << partner }

      it "is failing when a calendar is in an error state" do
        calendar = create(:calendar, organiser: partner)
        calendar.update!(calendar_state: "error")

        section = section_for(partner)

        expect(section).to be_failing
        expect(section.failing_calendars).to eq [calendar]
      end

      it "is failing when a calendar has a critical error recorded" do
        calendar = create(:calendar, organiser: partner)
        calendar.update!(critical_error: "SSL handshake failed")

        expect(section_for(partner)).to be_failing
      end
    end

    context "with no calendar" do
      let(:partner) { create(:partner) }

      before { user.partners << partner }

      it "builds a no_calendar section including manually-added upcoming events" do
        manual_event = create(:event, organiser: partner, calendar: nil, dtstart: 3.days.from_now)

        section = section_for(partner)

        expect(section).to be_no_calendar
        expect(section.upcoming_events).to eq [manual_event]
      end
    end
  end

  describe "#first_contact?" do
    it "is true when the user has never been sent a digest" do
      expect(described_class.new(user)).to be_first_contact
    end

    it "is false once a digest has been sent" do
      user.update!(partner_digest_last_sent_at: 1.month.ago)

      expect(described_class.new(user)).not_to be_first_contact
    end
  end
end
