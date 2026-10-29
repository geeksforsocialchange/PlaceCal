# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Calendars", type: :request do
  let(:partner) { create(:partner) }

  describe "GET /admin/calendars" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_calendars_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "loads the calendars page successfully" do
        get admin_calendars_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("Calendars")
      end
    end

    context "as a partner admin" do
      let(:user) { create(:partner_admin) }

      before { sign_in user }

      it "loads the calendars page successfully" do
        get admin_calendars_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("Calendars")
      end
    end
  end

  describe "GET /admin/calendars/:id" do
    let(:calendar) do
      cal = build(:calendar, organiser: partner)
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows the calendar details" do
        get admin_calendar_url(calendar, host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(calendar.name)
      end
    end
  end

  describe "GET /admin/calendars/new" do
    let!(:partner1) { create(:partner) }
    let!(:partner2) { create(:partner) }

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows the new calendar form with correct title" do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("<title>New Calendar | PlaceCal Admin</title>")
      end

      it "shows all partners in selector" do
        get new_admin_calendar_url(host: admin_host)
        expect(response.body).to include(partner1.name)
        expect(response.body).to include(partner2.name)
      end

      it "preselects partner when partner_id provided" do
        user.partners << partner1
        get new_admin_calendar_url(host: admin_host, params: { partner_id: partner1.id })
        expect(response).to be_successful
        expect(response.body).to include("selected")
      end
    end

    context "as a partner admin" do
      let(:user) { create(:partner_admin) }
      let(:admin_partner) { user.partners.first }

      before { sign_in user }

      it "shows only their partners in selector" do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(admin_partner.name)
      end
    end

    context "as a neighbourhood admin" do
      let(:ward) { create(:riverside_ward) }
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
      let!(:partner_in_neighbourhood) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address:)
      end

      before { sign_in user }

      it "shows partners in their neighbourhood" do
        get new_admin_calendar_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner_in_neighbourhood.name)
      end
    end
  end

  describe "GET /admin/calendars/:id/edit" do
    let(:user) { create(:root_user) }
    let!(:partner1) { create(:partner) }
    let!(:partner2) { create(:partner) }
    let(:calendar) do
      cal = build(:calendar, organiser: partner1, importer_mode: "ical")
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    before { sign_in user }

    it "shows the edit form" do
      get edit_admin_calendar_url(calendar, host: admin_host)
      expect(response).to be_successful
    end

    it "shows current importer selection" do
      get edit_admin_calendar_url(calendar, host: admin_host)
      expect(response.body).to include("ical")
    end

    describe "the API token field" do
      def api_token_fieldset(body)
        Nokogiri::HTML(body).at_css('fieldset[data-source-validator-target="apiTokenSection"]')
      end

      it "renders the field exactly once so the form does not submit duplicates" do
        get edit_admin_calendar_url(calendar, host: admin_host)
        inputs = Nokogiri::HTML(response.body).css('input[name="calendar[api_token]"]')
        expect(inputs.count).to eq(1)
      end

      it "shows the field for an importer that requires an API token" do
        api_calendar = build(:calendar, organiser: partner2, importer_mode: "ticketsource")
        allow(api_calendar).to receive(:check_source_reachable)
        api_calendar.save!

        get edit_admin_calendar_url(api_calendar, host: admin_host)

        fieldset = api_token_fieldset(response.body)
        expect(fieldset).to be_present
        expect(fieldset["class"]).not_to include("hidden")
      end

      it "hides the field for an importer that does not require an API token" do
        get edit_admin_calendar_url(calendar, host: admin_host)

        fieldset = api_token_fieldset(response.body)
        expect(fieldset).to be_present
        expect(fieldset["class"]).to include("hidden")
      end

      it "shows the field when a token is already saved" do
        tokened = build(:calendar, organiser: partner2, importer_mode: "ical", api_token: "skl-existing-token")
        allow(tokened).to receive(:check_source_reachable)
        tokened.save!

        get edit_admin_calendar_url(tokened, host: admin_host)

        fieldset = api_token_fieldset(response.body)
        expect(fieldset["class"]).not_to include("hidden")
      end

      it "advertises the api token parsers to the source-validator controller" do
        get edit_admin_calendar_url(calendar, host: admin_host)

        root = Nokogiri::HTML(response.body).at_css('[data-controller="source-validator"]')
        parsers = JSON.parse(root["data-source-validator-api-token-parsers-value"])
        expect(parsers).to include("ticketsource")
      end
    end
  end

  describe "POST /admin/calendars/test_source" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    it "returns warning for Ticket Tailor URLs" do
      post test_source_admin_calendars_url(host: admin_host),
           params: { source: "https://www.tickettailor.com/events/testorg" },
           as: :json

      expect(response).to be_successful
      json = response.parsed_body
      expect(json["valid"]).to be true
      expect(json["warning"]).to be true
      expect(json["warning_message"]).to include("API key")
      expect(json["importer_key"]).to eq("tickettailor")
      expect(json["importer_name"]).to eq("Ticket Tailor")
    end

    it "returns error for invalid URLs" do
      post test_source_admin_calendars_url(host: admin_host),
           params: { source: "not-a-url" },
           as: :json

      expect(response).to be_successful
      json = response.parsed_body
      expect(json["valid"]).to be false
      expect(json["error"]).to include("valid URL")
    end

    it "returns error for blank source" do
      post test_source_admin_calendars_url(host: admin_host),
           params: { source: "" },
           as: :json

      expect(response).to be_successful
      json = response.parsed_body
      expect(json["valid"]).to be false
      expect(json["error"]).to include("enter a URL")
    end

    it "refuses a private address without making a request" do
      post test_source_admin_calendars_url(host: admin_host),
           params: { source: "http://169.254.169.254/latest/meta-data/" },
           as: :json

      expect(response).to be_successful
      expect(response.parsed_body["valid"]).to be false
      expect(response.parsed_body["error"]).to eq(I18n.t("admin.calendars.wizard.source.private_address"))
      expect(a_request(:any, /.*/)).not_to have_been_made
    end

    it "returns error for unreachable URLs" do
      VCR.use_cassette(:example_dot_com_bad_response, allow_playback_repeats: true) do
        post test_source_admin_calendars_url(host: admin_host),
             params: { source: "https://example.com/" },
             as: :json

        expect(response).to be_successful
        json = response.parsed_body
        expect(json["valid"]).to be false
        expect(json["error"]).to be_present
      end
    end
  end

  describe "POST /admin/calendars" do
    let(:user) { create(:partner_admin) }
    let(:admin_partner) { user.partners.first }
    let(:other_partner) { create(:partner) }
    let(:calendar_params) do
      { name: "Weekly sessions", source: "https://example.com/weekly.ics", strategy: "event" }
    end

    before do
      allow_any_instance_of(Calendar).to receive(:check_source_reachable)
      sign_in user
    end

    it "creates a calendar for the user's own partner" do
      expect do
        post admin_calendars_url(host: admin_host),
             params: { calendar: calendar_params.merge(organiser_id: admin_partner.id) }
      end.to change(Calendar, :count).by(1)

      expect(Calendar.last.organiser).to eq(admin_partner)
    end

    it "does not create a calendar organised by a partner outside the user's scope" do
      expect do
        post admin_calendars_url(host: admin_host),
             params: { calendar: calendar_params.merge(organiser_id: other_partner.id) }
      end.not_to change(Calendar, :count)

      expect(other_partner.calendars).to be_empty
    end

    it "does not create a calendar whose default location is outside the user's scope" do
      expect do
        post admin_calendars_url(host: admin_host),
             params: { calendar: calendar_params.merge(organiser_id: admin_partner.id, place_id: other_partner.id) }
      end.not_to change(Calendar, :count)
    end
  end

  describe "PUT /admin/calendars/:id" do
    let(:user) { create(:partner_admin) }
    let(:admin_partner) { user.partners.first }
    let(:other_partner) { create(:partner) }
    let(:calendar) do
      cal = build(:calendar, organiser: admin_partner, importer_mode: "ical")
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    before { sign_in user }

    it "allows changing importer mode" do
      put admin_calendar_url(calendar, host: admin_host),
          params: { calendar: calendar.attributes.merge("importer_mode" => "eventbrite") }

      calendar.reload
      expect(calendar.importer_mode).to eq("eventbrite")
    end

    it "does not move the calendar to a partner outside the user's scope" do
      put admin_calendar_url(calendar, host: admin_host),
          params: { calendar: { organiser_id: other_partner.id } }

      expect(calendar.reload.organiser).to eq(admin_partner)
    end

    it "does not set a default location outside the user's scope" do
      put admin_calendar_url(calendar, host: admin_host),
          params: { calendar: { place_id: other_partner.id } }

      expect(calendar.reload.place).to be_nil
    end

    it "sets a default location to another partner the user manages" do
      venue = create(:partner)
      user.partners << venue

      put admin_calendar_url(calendar, host: admin_host),
          params: { calendar: { place_id: venue.id } }

      expect(response).to redirect_to(edit_admin_calendar_url(calendar, host: admin_host))
      expect(calendar.reload.place).to eq(venue)
    end

    it "keeps an existing default location outside the user's scope on an unrelated edit" do
      calendar.update_column(:place_id, other_partner.id) # rubocop:disable Rails/SkipsModelValidations

      put admin_calendar_url(calendar, host: admin_host),
          params: { calendar: { name: "Renamed calendar", place_id: other_partner.id } }

      calendar.reload
      expect(calendar.name).to eq("Renamed calendar")
      expect(calendar.place).to eq(other_partner)
    end
  end
end
