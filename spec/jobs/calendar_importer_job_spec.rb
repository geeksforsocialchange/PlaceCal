# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporterJob do
  # perform_now runs the full ActiveJob pipeline so that rescue_from handlers
  # (which catch and record the error) fire — calling #perform directly would
  # bypass them.
  subject(:perform_import) do
    described_class.perform_now(calendar.id, Time.zone.today, true)
  end

  # Use the factory's unique source sequence so the spec is independent of any
  # leftover calendar rows in the shared test database.
  let(:calendar) do
    create(:calendar, importer_mode: "ical")
      .tap { |c| c.update!(calendar_state: "in_queue") }
  end

  # Issue #3100: network timeouts and TLS failures while scraping third-party
  # feeds should mark the source as unreachable rather than surfacing as
  # unhandled exceptions in error tracking.
  describe "network/source-unreachable errors" do
    context "when the HTTP fetch times out (via read_http_source)" do
      before do
        stub_request(:get, calendar.source).to_raise(Net::ReadTimeout)
      end

      it "does not raise" do
        expect { perform_import }.not_to raise_error
      end

      it "marks the calendar as a bad (unreachable) source" do
        perform_import

        expect(calendar.reload.calendar_state).to eq("bad_source")
        expect(calendar.critical_error)
          .to eq(I18n.t("admin.calendars.wizard.source.unreachable"))
      end

      it "logs a warning describing the unreachable source" do
        allow(Rails.logger).to receive(:warn).and_call_original

        perform_import

        expect(Rails.logger).to have_received(:warn).with(/unreachable/i).at_least(:once)
      end
    end

    context "when a connection times out (Net::OpenTimeout)" do
      before do
        stub_request(:get, calendar.source).to_raise(Net::OpenTimeout)
      end

      it "does not raise and marks the source unreachable" do
        expect { perform_import }.not_to raise_error
        expect(calendar.reload.calendar_state).to eq("bad_source")
      end
    end

    context "when a TLS negotiation fails (OpenSSL::SSL::SSLError)" do
      before do
        stub_request(:get, calendar.source).to_raise(OpenSSL::SSL::SSLError)
      end

      it "does not raise and marks the source unreachable" do
        expect { perform_import }.not_to raise_error
        expect(calendar.reload.calendar_state).to eq("bad_source")
      end
    end

    context "when a timeout escapes a parser that bypasses read_http_source" do
      # API/POST-based parsers (TicketSource, ResidentAdvisor, Eventbrite) make
      # HTTP requests outside read_http_source, so the timeout reaches the job
      # directly. The job-level rescue_from is the backstop for these.
      before do
        task = instance_double(CalendarImporter::CalendarImporterTask)
        allow(CalendarImporter::CalendarImporterTask).to receive(:new).and_return(task)
        allow(task).to receive(:run).and_raise(Net::ReadTimeout)
      end

      it "does not raise and marks the source unreachable" do
        expect { perform_import }.not_to raise_error

        expect(calendar.reload.calendar_state).to eq("bad_source")
        expect(calendar.critical_error)
          .to eq(I18n.t("admin.calendars.wizard.source.unreachable"))
      end
    end

    context "when the import runs past MAX_RUN_TIME" do
      before do
        task = instance_double(CalendarImporter::CalendarImporterTask)
        allow(CalendarImporter::CalendarImporterTask).to receive(:new).and_return(task)
        allow(task).to receive(:run).and_raise(Timeout::Error, "execution expired")
      end

      it "does not raise and marks the source as too slow" do
        expect { perform_import }.not_to raise_error

        expect(calendar.reload.calendar_state).to eq("bad_source")
        expect(calendar.critical_error)
          .to eq(I18n.t("admin.calendars.wizard.source.too_slow", minutes: 2))
      end

      it "records the run as failed" do
        perform_import

        expect(calendar.import_runs.last).to have_attributes(outcome: "bad_source")
      end
    end

    context "when the Eventbrite API can't be reached" do
      let(:calendar) do
        create(:eventbrite_calendar, importer_mode: "eventbrite")
          .tap { |c| c.update!(calendar_state: "in_queue") }
      end
      let(:api) { %r{\Ahttps://www\.eventbriteapi\.com/v3/} }

      before { stub_request(:get, calendar.source).to_return(status: 200, body: "ok") }

      {
        "times out" => ->(stub) { stub.to_timeout },
        "times out at the socket" => ->(stub) { stub.to_raise(Errno::ETIMEDOUT) },
        "times out writing" => ->(stub) { stub.to_raise(Net::WriteTimeout) },
        "fails TLS" => ->(stub) { stub.to_raise(OpenSSL::SSL::SSLError.new("certificate verify failed")) }
      }.each do |failure, stub_with|
        it "marks the source unreachable when it #{failure}" do
          stub_with.call(stub_request(:get, api))

          expect { perform_import }.not_to raise_error
          expect(calendar.reload.calendar_state).to eq("bad_source")
          expect(calendar.critical_error)
            .to eq(I18n.t("admin.calendars.wizard.source.unreachable"))
        end
      end

      it "puts the calendar in the error state when its name doesn't resolve" do
        stub_request(:get, api).to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))

        expect { perform_import }.to raise_error(SocketError)
        expect(calendar.reload.calendar_state).to eq("error")
        expect(calendar.feed_empty_since).to be_nil
      end
    end
  end

  describe "Eventbrite API failures that are not network errors" do
    let(:calendar) do
      create(:eventbrite_calendar, importer_mode: "eventbrite")
        .tap { |c| c.update!(calendar_state: "in_queue") }
    end

    before { stub_request(:get, calendar.source).to_return(status: 200, body: "ok") }

    it "puts the calendar in the error state and reports a rejected token" do
      stub_request(:get, %r{\Ahttps://www\.eventbriteapi\.com/v3/}).to_return(status: 401, body: "{}")

      expect { perform_import }.to raise_error(CalendarImporter::Parsers::Eventbrite::ApiError, /HTTP 401/)
      expect(calendar.reload.calendar_state).to eq("error")
      expect(calendar.feed_empty_since).to be_nil
    end

    it "puts the calendar in the error state when the body isn't JSON" do
      stub_request(:get, %r{\Ahttps://www\.eventbriteapi\.com/v3/}).to_return(status: 200, body: "<html>Service page</html>")

      expect { perform_import }.not_to raise_error
      expect(calendar.reload.calendar_state).to eq("error")
      expect(calendar.critical_error).to include("un-parsable data")
      expect(calendar.feed_empty_since).to be_nil
    end
  end

  describe "non-network errors" do
    before do
      task = instance_double(CalendarImporter::CalendarImporterTask)
      allow(CalendarImporter::CalendarImporterTask).to receive(:new).and_return(task)
      allow(task).to receive(:run).and_raise(KeyError, "boom")
    end

    it "does not swallow unrelated StandardError exceptions" do
      # Unexpected exceptions are bugs we want surfaced in error tracking, so
      # the backstop re-raises rather than swallowing.
      expect { perform_import }.to raise_error(KeyError, /boom/)
    end

    it "still flags the calendar into a terminal state so it isn't stranded" do
      expect { perform_import }.to raise_error(KeyError)

      # Without this, the calendar would be stranded in `in_worker` forever.
      expect(calendar.reload.calendar_state).to eq("error")
      expect(calendar.critical_error).to include("boom")
    end
  end

  describe "an import that fails part-way" do
    before do
      stub_request(:get, calendar.source).to_return(status: 200, body: <<~ICS)
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:recover@example.com
        DTSTART:20221201T100000Z
        DTEND:20221201T110000Z
        SUMMARY:Recovered event
        END:VEVENT
        END:VCALENDAR
      ICS

      saves = 0
      allow_any_instance_of(CalendarImporter::EventResolver).to receive(:save_all_occurrences)
        .and_wrap_original do |original, *args|
          saves += 1
          saves == 1 ? raise("boom") : original.call(*args)
        end
    end

    it "imports the unchanged feed on the next scheduled run" do
      expect { perform_import }.to raise_error(RuntimeError, "boom")
      expect(calendar.reload.calendar_state).to eq("error")
      expect(calendar.events).to be_empty

      calendar.queue_for_import!(false, Time.current)
      described_class.perform_now(calendar.id, Time.zone.today, false)

      calendar.reload
      expect(calendar.calendar_state).to eq("idle")
      expect(calendar.critical_error).to be_nil
      expect(calendar.events.pluck(:summary)).to eq(["Recovered event"])
      expect(calendar.last_checksum).to be_present
    end
  end

  describe "a retried job for a calendar already in error" do
    let(:calendar) do
      create(:calendar, importer_mode: "ical")
        .tap { |c| c.update!(calendar_state: "error", critical_error: "earlier failure") }
    end

    before { stub_request(:get, calendar.source) }

    it "does no import work" do
      expect { perform_import }.not_to raise_error

      expect(a_request(:get, calendar.source)).not_to have_been_made
      expect(calendar.reload.calendar_state).to eq("error")
      expect(calendar.critical_error).to eq("earlier failure")
    end
  end

  describe "a default place without an address" do
    let(:place) { create(:ashton_service_area_partner).tap { |p| p.reload.clear_address! } }
    let(:calendar) do
      create(:calendar, strategy: "room_number", place:, importer_mode: "ical")
        .tap { |c| c.update!(calendar_state: "in_queue") }
    end

    before do
      stub_request(:get, calendar.source).to_return(status: 200, body: <<~ICS)
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:good@example.com
        DTSTART:20221201T100000Z
        DTEND:20221201T110000Z
        SUMMARY:Good event
        LOCATION:Room 2
        END:VEVENT
        BEGIN:VEVENT
        UID:no-summary@example.com
        DTSTART:20221202T100000Z
        DTEND:20221202T110000Z
        END:VEVENT
        END:VCALENDAR
      ICS
    end

    it "imports the valid events at the place and skips the invalid one" do
      perform_import

      expect(calendar.reload.calendar_state).to eq("idle")
      expect(calendar.events.pluck(:uid, :place_id, :address_id)).to eq([["good@example.com", place.id, nil]])
    end
  end

  describe "a TicketSource dates request that fails" do
    let(:calendar) do
      create(:calendar, source: "https://www.ticketsource.co.uk/fairfield-house",
                        importer_mode: "ticketsource", api_token: "test_key")
        .tap { |c| c.update!(calendar_state: "in_queue") }
    end

    def json(body)
      { status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" } }
    end

    def ts_event(id, name)
      { "id" => id, "attributes" => { "name" => name, "public" => true, "archived" => false } }
    end

    def ts_dates(id)
      { "data" => [{ "id" => id, "attributes" => { "start" => "2022-11-20T19:00:00+00:00",
                                                   "end" => "2022-11-20T21:00:00+00:00" } }] }
    end

    before do
      allow(CalendarImporter::Parsers::Base).to receive(:sleep)
      stub_request(:get, %r{api\.ticketsource\.io/events/\w+/venues}).to_return(json("data" => []))
      stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
        .to_return(json("data" => [ts_event("e1", "One"), ts_event("e2", "Two")]))
      stub_request(:get, "https://api.ticketsource.io/events/e1/dates?page=1&per_page=100").to_return(json(ts_dates("d1")))
      stub_request(:get, "https://api.ticketsource.io/events/e2/dates?page=1&per_page=100").to_return(json(ts_dates("d2")))
      perform_import
      calendar.reload.update!(calendar_state: "in_queue")
    end

    it "keeps that event's existing events and marks the source bad" do
      expect(calendar.events.pluck(:summary)).to contain_exactly("One", "Two")
      checksum = calendar.reload.last_checksum

      stub_request(:get, "https://api.ticketsource.io/events/e2/dates?page=1&per_page=100").to_return(status: 429)
      described_class.perform_now(calendar.id, Time.zone.today, true)

      expect(calendar.reload.calendar_state).to eq("bad_source")
      expect(calendar.events.pluck(:summary)).to contain_exactly("One", "Two")
      expect(calendar.last_checksum).to eq(checksum)
    end
  end
end
