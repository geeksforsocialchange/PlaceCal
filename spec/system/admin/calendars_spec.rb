# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Calendars", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partner_two) { create(:oldtown_library) }

  describe "Calendar links in the source field" do
    let(:calendar_id) { "abc123@group.calendar.google.com" }
    let(:feed_url) { "https://calendar.google.com/calendar/ical/abc123%40group.calendar.google.com/public/basic.ics" }
    let(:notice) { "We changed this to your calendar's feed address" }
    let(:eventbrite_link) { "https://www.eventbrite.co.uk/e/918839984127?aff=oddtdtcreator" }
    let(:eventbrite_organiser) { "https://www.eventbrite.co.uk/o/85889707613" }
    let(:luma_link) { "https://lu.ma/london-pattern-club" }
    let(:luma_feed) { "https://api.lu.ma/ics/get?entity=calendar&id=cal-8tfFZUVfInFAcNa" }

    before do
      allow(CalendarSourceResolver).to receive(:call).and_return(nil)
      allow(CalendarSourceResolver).to receive(:call).with(eventbrite_link)
                                                     .and_return(CalendarSourceResolver::Result.new(kind: "eventbrite", source: eventbrite_organiser))
      allow(CalendarSourceResolver).to receive(:call).with(luma_link)
                                                     .and_return(CalendarSourceResolver::Result.new(kind: "luma", source: luma_feed))
    end

    def await_source_controller
      page.document.synchronize do
        connected = page.evaluate_script(%(Stimulus.controllers.some((c) => c.identifier === "calendar-source")))
        raise Capybara::ElementNotFound, "calendar-source not connected" unless connected
      end
    end

    def await_lookup
      page.document.synchronize do
        pending = page.evaluate_script(%(Stimulus.controllers.find((c) => c.identifier === "calendar-source").pendingValue))
        raise Capybara::ExpectationNotMet, "source lookup still running" if pending
      end
    end

    def paste_source(url)
      await_source_controller
      page.execute_script(<<~JS, url)
        const input = document.querySelector("#calendar_source");
        input.value = arguments[0];
        input.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertFromPaste" }));
      JS
    end

    shared_examples "a form that rewrites calendar links" do
      it "rewrites a pasted embed link and says so", :aggregate_failures do
        paste_source("https://calendar.google.com/calendar/embed?src=#{calendar_id}&ctz=Europe%2FLondon")

        expect(page).to have_field("calendar_source", with: feed_url)
        expect(page).to have_content(notice)

        find("label", text: "Source URL", match: :first).click
        expect(page).to have_content(notice)
      end

      it "rewrites a pasted share link", :aggregate_failures do
        cid = Base64.strict_encode64(calendar_id).delete("=")
        paste_source("https://calendar.google.com/calendar/u/0?cid=#{cid}")

        expect(page).to have_field("calendar_source", with: feed_url)
        expect(page).to have_content(notice)
      end

      it "rewrites a typed link when the field loses focus" do
        fill_in "calendar_source", with: "https://calendar.google.com/calendar/embed?src=#{calendar_id}"
        find("label", text: "Source URL", match: :first).click

        expect(page).to have_field("calendar_source", with: feed_url)
      end

      it "leaves other links alone and hides the note", :aggregate_failures do
        paste_source("https://calendar.google.com/calendar/embed?src=#{calendar_id}")
        expect(page).to have_content(notice)

        paste_source("https://calendar.google.com/calendar/u/1/r/day/2024/8/23")

        expect(page).to have_field("calendar_source", with: "https://calendar.google.com/calendar/u/1/r/day/2024/8/23")
        expect(page).to have_no_content(notice)
      end

      it "swaps a pasted Eventbrite event link for the organiser's page and says so", :aggregate_failures do
        paste_source(eventbrite_link)

        expect(page).to have_field("calendar_source", with: eventbrite_organiser)
        expect(page).to have_content("We changed this to the organiser's Eventbrite page")
      end

      it "swaps a pasted Luma page for its feed and says so", :aggregate_failures do
        paste_source(luma_link)

        expect(page).to have_field("calendar_source", with: luma_feed)
        expect(page).to have_content("We changed this to your Luma calendar's feed address")
      end

      it "leaves a link it can't look up as pasted, without a note", :aggregate_failures do
        paste_source("https://lu.ma/no-such-calendar")
        await_lookup

        expect(page).to have_field("calendar_source", with: "https://lu.ma/no-such-calendar")
        expect(page).to have_no_content("We changed this")
        expect(CalendarSourceResolver).to have_received(:call).with("https://lu.ma/no-such-calendar")
      end
    end

    context "when editing a calendar" do
      let!(:calendar) { create(:calendar, organiser: partner, name: "Test Calendar") }

      before do
        click_link "Calendars"
        await_datatables
        click_link "Test Calendar"
      end

      it_behaves_like "a form that rewrites calendar links"
    end

    context "when adding a calendar" do
      before do
        click_link "Calendars"
        click_link "Add Calendar"
      end

      it_behaves_like "a form that rewrites calendar links"
    end
  end

  describe "testing a source" do
    let(:ics_url) { "https://example.com/events.ics" }
    let(:ticket_tailor_url) { "https://www.tickettailor.com/events/testorg" }
    let(:hidden_url) { "https://example.com/hidden-format" }
    let(:hidden_parser) do
      Class.new(CalendarImporter::Parsers::Base).tap do |parser|
        { NAME: "Hidden format", KEY: "hidden-format", PUBLIC: false }.each { |name, value| parser.const_set(name, value) }
      end
    end

    def stub_detection(parser)
      importer = instance_double(CalendarImporter::CalendarImporter, parser:, check_source!: nil)
      allow(CalendarImporter::CalendarImporter).to receive(:new).and_return(importer)
    end

    def stub_undetected_format
      importer = instance_double(CalendarImporter::CalendarImporter)
      allow(importer).to receive(:check_source!).and_raise(CalendarImporter::Exceptions::UnsupportedFeed)
      allow(CalendarImporter::CalendarImporter).to receive(:new).and_return(importer)
    end

    def open_wizard
      click_link "Calendars"
      click_link "Add Calendar"
      expect(page).to have_css("[data-wizard-connected='true']")
    end

    def test_source(url)
      fill_in "calendar_source", with: url
      click_button "Test"
    end

    def place_value
      page.evaluate_script(%(document.querySelector("#calendar_place_id").value))
    end

    context "when adding a calendar" do
      it "labels the step 1 button Continue once the source is valid", :aggregate_failures do
        stub_detection(CalendarImporter::Parsers::Ics)
        open_wizard
        test_source(ics_url)

        expect(page).to have_content("This URL is valid and ready to import!")
        expect(page).to have_button("Continue", exact: true)
        expect(page).to have_no_content("Save & Continue")
      end

      it "shows an API key note under a warning heading", :aggregate_failures do
        open_wizard
        test_source(ticket_tailor_url)

        within(".alert-warning") do
          expect(page).to have_content("This calendar needs an API key")
          expect(page).to have_content("Ticket Tailor uses an API key")
        end
        expect(page).to have_no_content("Unable to validate this URL")
      end

      it "sets the type to auto-detect when the detected type isn't in the type list", :aggregate_failures do
        stub_detection(CalendarImporter::Parsers::Ics)
        open_wizard
        test_source(ics_url)
        expect(page).to have_content("Detected format: Generic iCal")
        expect(find("#calendar_importer_mode", visible: :all).value).to eq("ical")

        stub_detection(hidden_parser)
        test_source(hidden_url)

        expect(page).to have_content("Hidden format")
        expect(find("#calendar_importer_mode", visible: :all).value).to eq("auto")
      end

      it "reopens on the step with the error and keeps what was entered", :aggregate_failures do
        stub_detection(CalendarImporter::Parsers::Ics)
        open_wizard
        test_source(ics_url)
        expect(page).to have_content("This URL is valid and ready to import!")
        click_button "Continue"

        tom_select partner.name, xpath: find("fieldset", text: "Partner Organiser").find(".ts-wrapper").path
        fill_in "calendar_name", with: "Riverside sessions"
        click_button "Continue"

        # Step 3 preselects the organiser as default location; clear it so the save fails
        expect(page).to have_content("Location Settings")
        page.document.synchronize { raise Capybara::ExpectationNotMet unless place_value == partner.id.to_s }
        page.execute_script(%(document.querySelector("#calendar_place_id").tomselect.clear()))
        click_button "Create Calendar"

        expect(page).to have_content("Place can't be blank with this strategy")
        expect(page).to have_content("Location Settings")
        expect(page).to have_no_content("Connect Your Calendar")
        expect(find("#calendar_importer_mode", visible: :all).value).to eq("ical")
        expect(find("#calendar_organiser_id", visible: :all).value).to eq(partner.id.to_s)

        click_button "Back"
        click_button "Back"
        expect(page).to have_content("This URL is valid and ready to import!")
        expect(page).to have_button("OK!")
        expect(page).to have_button("Continue", exact: true, disabled: false)
      end
    end

    context "when editing a calendar" do
      let!(:calendar) { create(:calendar, organiser: partner, name: "Test Calendar") }

      before do
        click_link "Calendars"
        await_datatables
        click_link "Test Calendar"
      end

      it "shows an API key note under a warning heading", :aggregate_failures do
        test_source(ticket_tailor_url)

        within(".alert-warning") do
          expect(page).to have_content("This calendar needs an API key")
          expect(page).to have_content("Ticket Tailor uses an API key")
        end
      end

      it "asks for a calendar type when the format isn't detected", :aggregate_failures do
        stub_undetected_format
        test_source("https://example.com/whats-on")

        within(".alert-warning") do
          expect(page).to have_content("We couldn't detect the calendar type")
          expect(page).to have_content("Choose its calendar type below")
        end
        expect(page).to have_no_content("Unable to validate this URL")

        select "Generic iCal / .ics", from: "calendar_importer_mode"
        expect(page).to have_content("This URL is valid and ready to import!")
        expect(page).to have_no_css(".alert-warning")
      end

      context "with a calendar type picked by hand" do
        let!(:calendar) do
          create(:calendar, organiser: partner, name: "Test Calendar")
            .tap { |c| c.update_column(:importer_mode, "ical") } # rubocop:disable Rails/SkipsModelValidations
        end

        it "sets the type to auto-detect when the detected type isn't in the type list", :aggregate_failures do
          expect(find("#calendar_importer_mode").value).to eq("ical")
          stub_detection(hidden_parser)
          test_source(hidden_url)

          expect(page).to have_content("This URL is valid and ready to import!")
          expect(find("#calendar_importer_mode").value).to eq("auto")
        end

        it "keeps it when the format isn't detected", :aggregate_failures do
          stub_undetected_format
          click_button "Test"

          expect(page).to have_content("This URL is valid and ready to import!")
          expect(page).to have_no_css(".alert-warning")
          expect(find("#calendar_importer_mode").value).to eq("ical")
        end
      end
    end
  end

  describe "tom-select inputs on calendar edit form" do
    let!(:calendar) { create(:calendar, organiser: partner, name: "Test Calendar") }

    it "allows changing partner organiser", :aggregate_failures do
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Partner organiser is on Source tab (default)
      expect(page).to have_content("Source")

      # Select a different partner using Tom Select
      partner_select_fieldset = find("fieldset", text: "Partner Organiser")
      partner_ts_wrapper = partner_select_fieldset.find(".ts-wrapper")
      tom_select partner_two.name, xpath: partner_ts_wrapper.path

      click_button "Save"

      # Verify success
      assert_has_flash(:success)

      # Verify data persists by re-editing
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Check partner changed
      partner_select = find("#calendar_organiser_id", visible: :all)
      expect(partner_select.value).to eq(partner_two.id.to_s)
    end

    it "allows changing default location", :aggregate_failures do
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Navigate to Location tab
      click_tab("location")

      # Wait for tab content
      expect(page).to have_content("Default Location")

      # Select default location using Tom Select
      place_select_fieldset = find("fieldset", text: "Default Location")
      place_ts_wrapper = place_select_fieldset.find(".ts-wrapper")
      tom_select partner_two.name, xpath: place_ts_wrapper.path

      click_button "Save"

      # Verify success
      assert_has_flash(:success)

      # Verify data persists by re-editing
      click_link "Calendars"
      await_datatables
      click_link "Test Calendar"

      # Navigate to Location tab and check default location
      click_tab("location")
      place_select = find("#calendar_place_id", visible: :all)
      expect(place_select.value).to eq(partner_two.id.to_s)
    end
  end

  describe "the import status strip" do
    let!(:calendar) { create(:calendar, organiser: partner, name: "Test Calendar") }
    let(:frame) { "turbo-frame#import_status_calendar_#{calendar.id}" }
    let(:announcer) { '[role="status"][data-import-status-target="announcer"]' }

    before do
      stub_const("Views::Admin::Calendars::ImporterOverview::POLL_INTERVAL", 0.2.seconds)
      calendar.update_columns(calendar_state: "in_queue") # rubocop:disable Rails/SkipsModelValidations
      visit admin_url("/calendars/#{calendar.id}/edit")
    end

    it "updates when the import finishes and leaves the form alone", :aggregate_failures do
      fill_in "calendar_name", with: "Unsaved name"
      expect(page).to have_css(frame, text: I18n.t("admin.calendars.importer.importing"))
      expect(page).to have_css(announcer, exact_text: "", visible: :all)

      calendar.update_columns(calendar_state: "idle", last_import_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

      expect(page).to have_css(frame, text: I18n.t("admin.calendars.importer.success"))
      expect(page).to have_css(announcer, exact_text: I18n.t("admin.calendars.importer.import_finished"), visible: :all)
      expect(page).to have_no_css("#{frame} [data-poll]")
      expect(page).to have_field("calendar_name", with: "Unsaved name")
    end

    it "reimports from the strip as a full page load" do
      calendar.update_columns(calendar_state: "idle", last_import_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      within(frame) { click_button I18n.t("admin.calendars.importer.reimport") }

      assert_has_flash(:success, I18n.t("admin.calendars.flash.queued"))
    end
  end
end
