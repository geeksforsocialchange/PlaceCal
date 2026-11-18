# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin event inspector", type: :request do
  let(:organiser) { create(:partner, name: "Oldtown Library") }
  let(:venue) { create(:partner, name: "Harbourside Arts Centre") }
  let(:calendar) do
    create(:calendar, name: "Library Google feed", organiser:, source: "https://calendar.google.com/library/basic.ics",
                      last_import_at: 2.hours.ago)
  end
  let!(:event) do
    create(:event, calendar:, organiser:, place: venue, summary: "Knit and natter", uid: "abc123@google.com",
                   publisher_url: "https://library.example/knit", rrule: [{ "table" => { "frequency" => "weekly" } }])
  end

  describe "GET /events/:id" do
    it "redirects a signed-out visitor to sign in" do
      get admin_event_url(event, host: admin_host)

      expect(response).to redirect_to(new_user_session_path)
    end

    context "as a root user" do
      before { sign_in create(:root_user) }

      it "shows the event, its source calendar and its partners, with no edit actions", :aggregate_failures do
        get admin_event_url(event, host: admin_host)

        expect(response).to have_http_status(:ok)
        html = Nokogiri::HTML(response.body)
        main = html.at_css("main")
        expect(main.text).to include("Knit and natter", "abc123@google.com", "Weekly", "Library Google feed",
                                     "https://calendar.google.com/library/basic.ics", I18n.t("admin.events.show.fields.last_import_at"),
                                     I18n.t("admin.jobs.states.#{calendar.reload.calendar_state}"))
        expect(main.at_css(%(a[href="https://library.example/knit"]))).to be_present
        expect(main.at_css(%(a[href="#{admin_calendar_path(calendar)}"]))).to be_present
        expect(main.at_css(%(a[href="#{edit_admin_partner_path(organiser)}"])).text).to eq("Oldtown Library")
        expect(main.at_css(%(a[href="#{edit_admin_partner_path(venue)}"])).text).to eq("Harbourside Arts Centre")
        expect(main.css("form, button")).to be_empty
      end

      it "lists upcoming events from the same calendar with the same summary, with a count" do
        create(:event, calendar:, organiser:, summary: "Knit and natter", dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour)
        create(:event, calendar:, organiser:, summary: "Knit and natter", dtstart: 2.weeks.from_now, dtend: 2.weeks.from_now + 1.hour)
        create(:event, calendar:, organiser:, summary: "Knit and natter", dtstart: 1.week.ago, dtend: 1.week.ago + 1.hour)
        create(:event, calendar:, organiser:, summary: "Book club", dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour)
        create(:event, organiser:, summary: "Knit and natter", dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour)

        get admin_event_url(event, host: admin_host)

        expect(response.body).to include(I18n.t("admin.events.show.siblings_count", upcoming: 2, total: 3))
        expect(Nokogiri::HTML(response.body).css("main table tbody tr").size).to eq(2)
      end
    end

    context "as an admin who can edit the event's calendar" do
      let(:user) { create(:partner_admin) }
      let(:organiser) { user.partners.first }

      before { sign_in user }

      it "shows the event and the calendar's feed URL" do
        get admin_event_url(event, host: admin_host)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Knit and natter", "https://calendar.google.com/library/basic.ics")
      end
    end

    context "as an admin who cannot edit the event's calendar" do
      before { sign_in create(:partner_admin) }

      it "shows the event but not the calendar's feed URL, which may be a secret link" do
        get admin_event_url(event, host: admin_host)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Knit and natter", "Library Google feed")
        expect(response.body).not_to include("https://calendar.google.com/library/basic.ics")
      end
    end

    context "as a citizen with no admin role" do
      before { sign_in create(:citizen_user) }

      it "turns them away" do
        get admin_event_url(event, host: admin_host)

        expect(response).to redirect_to(admin_root_path)
      end
    end

    context "with an event from no calendar" do
      let(:user) { create(:partner_admin) }
      let(:uncalendared) { create(:event, calendar: nil, organiser: user.partners.first, summary: "Hand-made event") }

      it "shows any admin that it has no calendar and no siblings section" do
        sign_in user
        get admin_event_url(uncalendared, host: admin_host)

        expect(response.body).to include("Hand-made event", I18n.t("admin.events.show.no_calendar"))
        expect(response.body).not_to include(I18n.t("admin.events.show.siblings"))
      end
    end
  end

  describe "GET /events/lookup" do
    before { sign_in create(:root_user) }

    [
      "https://manchester.placecal.org/events/ID",
      "http://lvh.me:3000/events/ID.ics",
      "webcal://placecal.org/events/ID.ics",
      "placecal.org/events/ID",
      "  https://placecal.org/events/ID/?utm_source=email#top ",
      "/events/ID",
      "ID",
      " ID "
    ].each do |query|
      it "goes to the event's page from #{query.inspect}" do
        get lookup_admin_events_url(host: admin_host, q: query.sub("ID", event.id.to_s))

        expect(response).to redirect_to(admin_event_path(event))
      end
    end

    [
      "https://placecal.org/events/2026/11/18",
      "https://placecal.org/partners/ID",
      "NEXT_ID",
      "99999999999999999999999",
      "knit and natter"
    ].each do |query|
      it "shows the lookup page again with a warning for #{query.inspect}" do
        q = query.sub("NEXT_ID", (event.id + 1000).to_s).sub("ID", event.id.to_s)
        get lookup_admin_events_url(host: admin_host, q:)

        expect(response).to have_http_status(:ok)
        html = Nokogiri::HTML(response.body)
        expect(html.at_css("main [role=alert]").text).to eq(I18n.t("admin.events.lookup.not_found"))
        expect(html.at_css("main input[name=q]")[:value]).to eq(q.strip)
      end
    end

    it "shows the lookup box at the top of its page, with no warning, when nothing has been looked up" do
      get lookup_admin_events_url(host: admin_host)

      html = Nokogiri::HTML(response.body)
      expect(html.at_css("main h1").text).to eq(I18n.t("admin.events.lookup.title"))
      expect(html.at_css("main form[role=search] input[name=q]")).to be_present
      expect(html.at_css("main [role=alert]")).to be_nil
    end

    it "turns away a citizen" do
      sign_in create(:citizen_user)
      get lookup_admin_events_url(host: admin_host)

      expect(response).to redirect_to(admin_root_path)
    end
  end

  it "links the lookup page from the admin menu and keeps the top bar free of it" do
    sign_in create(:partner_admin)
    get admin_root_url(host: admin_host)

    html = Nokogiri::HTML(response.body)
    expect(html.at_css(%(nav a[href="#{lookup_admin_events_path}"])).text.strip).to eq(I18n.t("admin.leftbar.find_event"))
    expect(html.at_css("header form[role=search]")).to be_nil
    headings = html.css("nav h2").map { it.text.strip.downcase }
    expect(headings.index(I18n.t("admin.leftbar.tools").downcase)).to eq(headings.index(I18n.t("admin.leftbar.get_support").downcase) - 1)
  end
end
