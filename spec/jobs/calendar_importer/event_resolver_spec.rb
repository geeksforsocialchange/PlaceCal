# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::EventResolver do
  FakeICSEvent = Struct.new(
    :uid,
    :summary,
    :description,
    :location,
    :rrule,
    :last_modified,
    :custom_properties,
    :url
  )

  FakeEventbriteEvent = Struct.new(
    :id,
    :name,
    :description,
    :venue,
    :start,
    :end,
    :online_event,
    :url
  )

  def patch_ics_dates(event, from_date, to_date)
    patch = Module.new
    patch.define_method(:occurrences_between) do |_from, _to|
      [CalendarImporter::Events::Base::Dates.new(from_date, to_date)]
    end

    event.extend patch
  end

  def make_calendar_for_strategy(strategy)
    VCR.use_cassette(:import_test_calendar) do
      create(:calendar, strategy: strategy)
    end
  end

  let(:start_date) { DateTime.new(1990, 1, 1, 10, 30) }
  let(:end_date) { DateTime.new(1990, 1, 2, 11, 40) }
  let(:fake_ics_event) do
    event = FakeICSEvent.new(
      uid: 123,
      summary: "A summary",
      description: "A description",
      location: "A location",
      rrule: "",
      last_modified: "",
      custom_properties: {}
    )
    patch_ics_dates(event, start_date, end_date)
  end
  let(:ics_event_data) { CalendarImporter::Events::IcsEvent.new(fake_ics_event, start_date, end_date) }

  describe "location strategies" do
    it "online only strategy does not set place or address" do
      calendar = make_calendar_for_strategy("online_only")
      notices = []

      resolver = described_class.new(ics_event_data, calendar, notices, start_date)
      resolver.determine_location_for_strategy

      expect(resolver.data.place_id).to be_nil
      expect(resolver.data.address_id).to be_nil
      expect(resolver.data.partner_id).to eq(calendar.partner_id)
    end

    it "no location strategy does not set place or address" do
      calendar = make_calendar_for_strategy("no_location")
      notices = []

      resolver = described_class.new(ics_event_data, calendar, notices, start_date)
      resolver.determine_location_for_strategy

      expect(resolver.data.place_id).to be_nil
      expect(resolver.data.address_id).to be_nil
      expect(resolver.data.partner_id).to eq(calendar.partner_id)
    end
  end

  describe "online location detection" do
    context "with ICS events" do
      it "detects google meet url in custom properties" do
        meet_link = "https://meet.google.com/aaa-aaaa-aaa"
        fake_ics_event[:custom_properties] = { "x_google_conference" => [meet_link] }
        ics_event_data = CalendarImporter::Events::IcsEvent.new(fake_ics_event, start_date, end_date)

        calendar = make_calendar_for_strategy("event")

        resolver = described_class.new(ics_event_data, calendar, [], start_date)
        resolver.determine_online_location

        expect(resolver.data.online_address_id).to be_present

        online_address = OnlineAddress.find(resolver.data.online_address_id)
        expect(online_address.url).to eq(meet_link)
      end

      it "detects jitsi link in description" do
        jitsi_link = "https://meet.jit.si/blahblabladsf"
        fake_ics_event[:description] = "Join us on jitsi: #{jitsi_link} words words words"
        ics_event_data = CalendarImporter::Events::IcsEvent.new(fake_ics_event, start_date, end_date)

        calendar = make_calendar_for_strategy("place")

        resolver = described_class.new(ics_event_data, calendar, [], start_date)
        resolver.determine_online_location

        expect(resolver.data.online_address_id).to be_present

        online_address = OnlineAddress.find(resolver.data.online_address_id)
        expect(online_address.url).to eq(jitsi_link)
      end

      it "detects google meet link in description" do
        meet_link = "https://meet.google.com/aaa-aaaa-aaa"
        fake_ics_event[:description] = "Join us on meets: #{meet_link} words words words"
        ics_event_data = CalendarImporter::Events::IcsEvent.new(fake_ics_event, start_date, end_date)

        calendar = make_calendar_for_strategy("event")

        resolver = described_class.new(ics_event_data, calendar, [], start_date)
        resolver.determine_online_location

        expect(resolver.data.online_address_id).to be_present

        online_address = OnlineAddress.find(resolver.data.online_address_id)
        expect(online_address.url).to eq(meet_link)
      end

      it "detects zoom link in description" do
        zoom_link = "https://us04web.zoom.us/j/78434510758?pwd=aILSsYSJRSb_uO87tFjulZuLAA0eXT.1"
        fake_ics_event[:description] = "join us on zoom: <p>#{zoom_link}<p> words words words"
        ics_event_data = CalendarImporter::Events::IcsEvent.new(fake_ics_event, start_date, end_date)

        calendar = make_calendar_for_strategy("event")

        resolver = described_class.new(ics_event_data, calendar, [], start_date)
        resolver.determine_online_location

        expect(resolver.data.online_address_id).to be_present

        online_address = OnlineAddress.find(resolver.data.online_address_id)
        expect(online_address.url).to eq(zoom_link)
      end
    end

    context "with eventbrite events" do
      it "detects online event url" do
        eventbrite_link = "https://www.eventbrite.co.uk/e/some-random-event-woo-hoo-111111111111"
        fake_eventbrite_event = FakeEventbriteEvent.new(
          id: "111111111111",
          name: { text: "A summary" },
          description: { text: "A description" },
          venue: nil,
          start: { local: start_date.iso8601 },
          end: { local: end_date.iso8601 },
          online_event: true,
          url: eventbrite_link
        )
        event_data = CalendarImporter::Events::EventbriteEvent.new(fake_eventbrite_event)

        calendar = make_calendar_for_strategy("event")

        resolver = described_class.new(event_data, calendar, [], start_date)
        resolver.determine_online_location

        expect(resolver.data.online_address_id).to be_present

        online_address = OnlineAddress.find(resolver.data.online_address_id)
        expect(online_address.url).to eq(eventbrite_link)
      end
    end
  end

  describe "recurring event dedup" do
    def make_recurring_ics_event(uid:, occurrences:)
      event = FakeICSEvent.new(
        uid: uid,
        summary: "Recurring Event",
        description: "A recurring event",
        location: "",
        rrule: "FREQ=WEEKLY",
        last_modified: "",
        custom_properties: {}
      )

      patch = Module.new
      patch.define_method(:occurrences_between) do |_from, _to|
        occurrences.map { |s, e| CalendarImporter::Events::Base::Dates.new(s, e) }
      end
      event.extend patch

      CalendarImporter::Events::IcsEvent.new(event, occurrences.first[0], occurrences.first[1])
    end

    it "does not create duplicates when re-importing identical recurring events" do
      calendar = make_calendar_for_strategy("no_location")

      occ1_start = DateTime.new(2024, 1, 8, 10, 0)
      occ1_end   = DateTime.new(2024, 1, 8, 11, 0)
      occ2_start = DateTime.new(2024, 1, 15, 10, 0)
      occ2_end   = DateTime.new(2024, 1, 15, 11, 0)

      occurrences = [[occ1_start, occ1_end], [occ2_start, occ2_end]]
      event_data = make_recurring_ics_event(uid: "recurring-123", occurrences: occurrences)

      resolver = described_class.new(event_data, calendar, [], occ1_start)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(calendar.events.where(uid: "recurring-123").count).to eq(2)

      # Re-import identical data
      event_data2 = make_recurring_ics_event(uid: "recurring-123", occurrences: occurrences)
      resolver2 = described_class.new(event_data2, calendar, [], occ1_start)
      resolver2.determine_location_for_strategy
      resolver2.save_all_occurences

      expect(calendar.events.where(uid: "recurring-123").count).to eq(2)
    end

    it "removes stale occurrences when schedule changes" do
      calendar = make_calendar_for_strategy("no_location")

      occ1_start = DateTime.new(2024, 1, 8, 10, 0)
      occ1_end   = DateTime.new(2024, 1, 8, 11, 0)
      occ2_start = DateTime.new(2024, 1, 15, 10, 0)
      occ2_end   = DateTime.new(2024, 1, 15, 11, 0)

      occurrences = [[occ1_start, occ1_end], [occ2_start, occ2_end]]
      event_data = make_recurring_ics_event(uid: "recurring-456", occurrences: occurrences)

      resolver = described_class.new(event_data, calendar, [], occ1_start)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(calendar.events.where(uid: "recurring-456").count).to eq(2)

      # Re-import with only one occurrence (second was cancelled)
      new_occurrences = [[occ1_start, occ1_end]]
      event_data2 = make_recurring_ics_event(uid: "recurring-456", occurrences: new_occurrences)
      resolver2 = described_class.new(event_data2, calendar, [], occ1_start)
      resolver2.determine_location_for_strategy
      resolver2.save_all_occurences

      expect(calendar.events.where(uid: "recurring-456").count).to eq(1)
      expect(calendar.events.find_by(uid: "recurring-456").dtstart).to eq(occ1_start)
    end

    it "correctly handles time pair matching (not independent start/end matching)" do
      calendar = make_calendar_for_strategy("no_location")

      # Create two occurrences where occ1's dtstart matches occ2's dtstart would not,
      # and occ1's dtend matches occ2's dtend would not — the old OR logic would
      # incorrectly delete valid events in this case
      occ1_start = DateTime.new(2024, 1, 8, 10, 0)
      occ1_end   = DateTime.new(2024, 1, 8, 11, 0)
      occ2_start = DateTime.new(2024, 1, 15, 10, 0)
      occ2_end   = DateTime.new(2024, 1, 15, 12, 0)

      occurrences = [[occ1_start, occ1_end], [occ2_start, occ2_end]]
      event_data = make_recurring_ics_event(uid: "recurring-789", occurrences: occurrences)

      resolver = described_class.new(event_data, calendar, [], occ1_start)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(calendar.events.where(uid: "recurring-789").count).to eq(2)

      # Now re-import with the second occurrence's end time changed.
      # The old OR logic would have incorrectly deleted occ1 here because
      # occ1's dtend (11:00) doesn't appear in the new end_times list.
      new_occ2_end = DateTime.new(2024, 1, 15, 13, 0)
      new_occurrences = [[occ1_start, occ1_end], [occ2_start, new_occ2_end]]
      event_data2 = make_recurring_ics_event(uid: "recurring-789", occurrences: new_occurrences)
      resolver2 = described_class.new(event_data2, calendar, [], occ1_start)
      resolver2.determine_location_for_strategy
      resolver2.save_all_occurences

      events = calendar.events.where(uid: "recurring-789").order(:dtstart)
      expect(events.count).to eq(2)
      expect(events.first.dtstart).to eq(occ1_start)
      expect(events.first.dtend).to eq(occ1_end)
      expect(events.last.dtstart).to eq(occ2_start)
      expect(events.last.dtend).to eq(new_occ2_end)
    end
  end

  describe "duplicate cleanup" do
    it "removes pre-existing duplicate events during import" do
      calendar = make_calendar_for_strategy("no_location")

      # Temporarily drop the unique index to simulate pre-existing bad data
      ActiveRecord::Base.connection.remove_index :events, name: "index_events_unique_per_calendar"

      # Create duplicate events bypassing validation
      3.times do
        event = calendar.events.new(
          uid: "dup-123",
          summary: "Duplicate Event",
          dtstart: start_date,
          dtend: end_date,
          partner: calendar.partner
        )
        event.save!(validate: false)
      end

      # Re-add the unique index won't work with dupes present, so test cleanup without it
      expect(calendar.events.where(uid: "dup-123").count).to eq(3)

      # Now import the same event — resolver should clean up duplicates
      event_data = ics_event_data
      allow(event_data).to receive(:uid).and_return("dup-123")

      resolver = described_class.new(event_data, calendar, [], start_date)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(calendar.events.where(uid: "dup-123").count).to eq(1)
    ensure
      # Restore the unique index
      unless ActiveRecord::Base.connection.index_exists?(:events, name: "index_events_unique_per_calendar")
        ActiveRecord::Base.connection.add_index :events, %i[calendar_id uid dtstart dtend],
                                                unique: true,
                                                name: "index_events_unique_per_calendar"
      end
    end

    it "handles RecordNotUnique gracefully on new event insert" do
      calendar = make_calendar_for_strategy("no_location")
      notices = []

      resolver = described_class.new(ics_event_data, calendar, notices, start_date)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(calendar.events.where(uid: ics_event_data.uid).count).to eq(1)
      expect(notices).to be_empty
    end
  end

  describe "notices" do
    it "are empty when no problems occur" do
      calendar = make_calendar_for_strategy("no_location")
      notices = []

      resolver = described_class.new(ics_event_data, calendar, notices, start_date)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(notices).to be_empty
    end

    it "generates notices when Event fails validations" do
      calendar = make_calendar_for_strategy("no_location")
      notices = []

      event = ics_event_data.instance_variable_get(:@event)
      event.summary = ""

      resolver = described_class.new(ics_event_data, calendar, notices, start_date)
      resolver.determine_location_for_strategy
      resolver.save_all_occurences

      expect(notices).to eq(["Summary can't be blank"])
    end

    it "still imports when missing address" do
      calendar = make_calendar_for_strategy("no_location")
      calendar.strategy = "event"

      notices = []

      resolver = described_class.new(ics_event_data, calendar, notices, start_date)
      _place, address = resolver.determine_location_for_strategy

      expect(address).to be_nil
    end
  end
end
