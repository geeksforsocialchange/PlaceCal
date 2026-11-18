# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Import runs", :slow, type: :system do
  include_context "admin login"

  let(:folk_club) { create(:calendar, name: "Folk club feed") }
  let(:sanctuary) { create(:calendar, name: "Sanctuary feed") }

  let!(:imported) do
    folk_club.import_runs.create!(started_at: 6.minutes.ago).tap do |run|
      run.finish!(outcome: "imported", importer: "ical", events_added: 3, events_changed: 12, events_removed: 1, events_skipped: 2,
                  events: [{ uid: "a", title: "Sing-around", location: "The Castle, Oldham Street", location_result: "event_address", reason: nil, occurrences: 4 },
                           { uid: "b", title: "Old fair", location: nil, location_result: "skipped", reason: "No dates from today onwards", occurrences: 0 }])
    end
  end

  let!(:failed) do
    sanctuary.import_runs.create!(started_at: 4.minutes.ago).tap do |run|
      run.finish!(outcome: "bad_source", error: "This URL returned a 404 (not found).")
    end
  end

  it "lists runs newest first, with a failed run's error on a line beneath it, and filters by outcome" do
    visit admin_url("/jobs")

    rows = all("tbody tr", minimum: 3)
    expect(rows[0]).to have_text("Sanctuary feed").and have_text("Bad source")
    expect(rows[1]).to have_text("This URL returned a 404 (not found).")
    expect(rows[0][:class]).to include("bg-red-50")
    expect(rows[1][:class]).to include("bg-red-50")
    expect(rows[2]).to have_text("Folk club feed").and have_text("Imported").and have_text("12")

    within("[data-filter-column='outcome']") { click_button "Failed" }
    expect(page).to have_no_text("Folk club feed")
    expect(page).to have_text("Sanctuary feed")
  end

  it "links each run by its number to a page of how each event in the feed was placed" do
    visit admin_url("/jobs")
    click_link "##{imported.id}"

    expect(page).to have_css("h1", text: "Import run ##{imported.id}")
    expect(page).to have_text("3 added, 12 changed, 1 removed, 2 skipped")
    within("table") do
      expect(page).to have_text("Sing-around").and have_text("Its own address")
      expect(page).to have_text("Old fair").and have_text("No dates from today onwards")
    end
  end
end
