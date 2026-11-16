# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin calendar wizard after a failed create", type: :request do
  let(:user) { create(:partner_admin) }
  let(:admin_partner) { user.partners.first }
  let(:calendar_params) do
    { name: "Weekly sessions", source: "https://example.com/weekly.ics", strategy: "event" }
  end

  before do
    allow_any_instance_of(Calendar).to receive(:check_source_reachable)
    sign_in user
  end

  def post_calendar(**overrides)
    post admin_calendars_url(host: admin_host),
         params: { calendar: calendar_params.merge(organiser_id: admin_partner.id, importer_mode: "ical", **overrides) }
    Nokogiri::HTML(response.body)
  end

  def wizard(html, value) = html.at_css("[data-controller='calendar-wizard']")["data-calendar-wizard-#{value}-value"]

  def target_classes(html, target) = html.at_css("[data-calendar-wizard-target='#{target}']")["class"]

  it "reopens on the location step and keeps the tested source, type and organiser", :aggregate_failures do
    html = post_calendar(strategy: "place", place_id: "")

    expect(response).to have_http_status(:unprocessable_content)
    expect(wizard(html, "current-step")).to eq("3")
    expect(wizard(html, "source-valid")).to eq("true")
    expect(html.at_css("#calendar_importer_mode option[selected]")["value"]).to eq("ical")
    expect(html.at_css("#calendar_organiser_id option[selected]")["value"]).to eq(admin_partner.id.to_s)
  end

  it "reopens on the organiser step when the name is missing" do
    expect(wizard(post_calendar(name: ""), "current-step")).to eq("2")
  end

  it "reopens on the source step, untested but with the type list showing, when the source is invalid", :aggregate_failures do
    html = post_calendar(source: "not a url")

    expect(wizard(html, "current-step")).to eq("1")
    expect(wizard(html, "source-valid")).to eq("false")
    expect(target_classes(html, "importerModeSection")).not_to include("hidden")
  end

  it "keeps the API key note and field for an API source", :aggregate_failures do
    html = post_calendar(strategy: "place", place_id: "", importer_mode: "tickettailor", api_token: "tt-key")

    expect(html.at_css("[data-calendar-wizard-target='sourceWarning']").text).to include("needs an API key")
    expect(target_classes(html, "sourceWarning")).not_to include("hidden")
    expect(target_classes(html, "sourceSuccess")).to include("hidden")
    expect(target_classes(html, "apiTokenSection")).not_to include("hidden")
  end
end
