# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin calendar import status", type: :request do
  let(:admin_host) { "admin.lvh.me" }
  let(:partner) { create(:partner) }
  let(:calendar) { create(:calendar, organiser: partner) }
  let(:html) { Nokogiri::HTML(response.body) }
  let(:state) { html.at_css('[data-import-status-target="state"]') }

  def set_state(calendar_state, critical_error: nil)
    calendar.update_columns(calendar_state:, critical_error:, last_import_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations
  end

  context "when signed in as a root user" do
    before { sign_in create(:root_user) }

    it "renders only the strip, inside its frame", :aggregate_failures do
      get import_status_admin_calendar_url(calendar, host: admin_host)

      expect(response).to be_successful
      expect(response.body).not_to include("<html")
      expect(html.at_css("turbo-frame#import_status_calendar_#{calendar.id}")).to be_present
      expect(html.at_css('[role="status"]')).to be_present
    end

    %w[in_queue in_worker].each do |busy_state|
      it "keeps polling while the calendar is #{busy_state}", :aggregate_failures do
        set_state(busy_state)
        get import_status_admin_calendar_url(calendar, host: admin_host)

        expect(state["data-poll"]).not_to be_nil
        expect(state["data-announcement"]).to be_nil
        expect(response.body).to include(I18n.t("admin.calendars.importer.importing"))
      end
    end

    it "stops polling and announces success when idle", :aggregate_failures do
      set_state("idle")
      get import_status_admin_calendar_url(calendar, host: admin_host)

      expect(state["data-poll"]).to be_nil
      expect(state["data-announcement"]).to eq(I18n.t("admin.calendars.importer.import_finished"))
      expect(response.body).to include(I18n.t("admin.calendars.importer.success"))
      expect(html.at_css("form[action='#{import_admin_calendar_path(calendar)}'][data-turbo-frame='_top']")).to be_present
    end

    %w[error bad_source].each do |failed_state|
      it "stops polling and announces failure when #{failed_state}", :aggregate_failures do
        set_state(failed_state, critical_error: "The feed could not be read")
        get import_status_admin_calendar_url(calendar, host: admin_host)

        expect(state["data-poll"]).to be_nil
        expect(state["data-announcement"]).to eq(I18n.t("admin.calendars.importer.import_failed"))
        expect(response.body).to include("The feed could not be read")
        expect(html.at_css("form[action='#{import_admin_calendar_path(calendar)}'][data-turbo-frame='_top']")).to be_present
      end
    end
  end

  context "when signed in as an admin of the calendar's partner" do
    before { sign_in create(:partner_admin, partner:) }

    it "renders the strip" do
      get import_status_admin_calendar_url(calendar, host: admin_host)
      expect(response).to be_successful
    end
  end

  context "when signed in as an admin without access to the calendar" do
    before { sign_in create(:partner_admin) }

    it "responds as the calendar page does", :aggregate_failures do
      get admin_calendar_url(calendar, host: admin_host)
      show_status = response.status
      show_location = response.location

      get import_status_admin_calendar_url(calendar, host: admin_host)

      expect(response).to redirect_to(admin_root_path)
      expect([response.status, response.location]).to eq([show_status, show_location])
    end
  end

  context "when not signed in" do
    it "redirects to the sign in page" do
      get import_status_admin_calendar_url(calendar, host: admin_host)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
