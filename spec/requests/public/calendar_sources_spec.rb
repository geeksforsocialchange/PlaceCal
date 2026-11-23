# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Calendar sources list", type: :request do
  let(:parsers) { CalendarImporter::CalendarImporter.public_parsers }
  let(:payload) { response.parsed_body }
  let(:sources) { payload["sources"].index_by { |source| source["key"] } }

  before { get "http://lvh.me/api/v1/calendar_sources" }

  it "is public JSON that shared caches can keep", :aggregate_failures do
    expect(response).to be_successful
    expect(response.media_type).to eq("application/json")
    expect(response.headers["Cache-Control"]).to include("public", "max-age=3600")
    expect(payload["version"]).to eq(1)
  end

  it "lists every source offered to admins, by name" do
    expect(payload["sources"].pluck("name")).to eq(parsers.map { |parser| parser::NAME }.sort_by(&:downcase))
  end

  it "names each event field in the words the admin uses" do
    expect(payload["fields"]).to include({ "key" => "online_link", "label" => "Meeting link" })
    expect(payload["fields"].pluck("key")).to eq(CalendarImporter::Events::Base::FIELDS.keys.map(&:to_s))
  end

  it "explains the three tiers, most open first" do
    expect(payload["tiers"].pluck("key")).to eq(%w[gold silver bronze])
    expect(payload["tiers"].first).to include("label" => "Gold: open standard", "description" => a_string_including("iCal or schema.org"))
  end

  it "gives every source one of those tiers" do
    expect(payload["sources"].pluck("tier").uniq).to match_array(%w[gold silver bronze])
  end

  it "describes a source from its parser", :aggregate_failures do
    expect(sources["tickettailor"]).to include(
      "name" => "Ticket Tailor", "domains" => %w[www.tickettailor.com tickettailor.com], "handbook_page" => "ticket-tailor",
      "tier" => "silver", "ticketing" => true, "requires_api_token" => true
    )
    expect(sources["meetup"]).to include("tier" => "gold", "ticketing" => false, "requires_api_token" => false)
    expect(sources["ld-json"]).to include("name" => "JSON-LD", "domains" => [], "tier" => "gold")
    expect(sources["residentadvisor"]["tier"]).to eq("bronze")
  end

  it "lists only the event fields a source fills", :aggregate_failures do
    expect(sources["ical"]["imports"]).to include("title", "repeats", "online_link")
    expect(sources["ticket-solve"]["imports"]).to include("spaces_available")
    expect(sources["ticket-solve"]["imports"]).not_to include("end_time", "sold_out")
  end
end
