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

    context "when the Eventbrite parser's RestClient fetch times out" do
      # Eventbrite imports via RestClient (EventbriteSDK), not read_http_source,
      # so its timeouts are RestClient::Exceptions::ReadTimeout — not Net:: errors
      # — and propagate through the importer task to this job-level backstop (#3100).
      let(:calendar) do
        create(:eventbrite_calendar, importer_mode: "eventbrite")
          .tap { |c| c.update!(calendar_state: "in_queue") }
      end

      before do
        # The Eventbrite source page is reachable (validate_feed! passes)...
        stub_request(:get, calendar.source).to_return(status: 200, body: "ok")
        # ...but the Eventbrite API fetch (RestClient via EventbriteSDK) times out.
        allow(EventbriteSDK::Organizer).to receive(:retrieve)
          .and_raise(RestClient::Exceptions::ReadTimeout)
      end

      it "does not raise and marks the source unreachable" do
        expect { perform_import }.not_to raise_error

        expect(calendar.reload.calendar_state).to eq("bad_source")
        expect(calendar.critical_error)
          .to eq(I18n.t("admin.calendars.wizard.source.unreachable"))
      end
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
end
