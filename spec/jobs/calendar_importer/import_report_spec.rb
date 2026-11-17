# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::ImportReport do
  subject(:report) { described_class.new }

  let(:importer) { "admin.calendars.importer" }

  {
    unreadable_event_dates: ["unreadable_event_dates", { event: "Broken", error: 'Failed to parse "2026-11-0X"' }],
    occurrence_limit: ["occurrence_limit", { summary: "Every minute", count: 1000 }],
    calendar_occurrence_limit: ["calendar_occurrence_limit", { count: 20_000 }],
    empty_feed: ["feed_empty", { count: 2, since: "8 November 2022", removal: "10 November 2022" }],
    unreadable_address: ["unreadable_address.no_postcode", { count: 2, examples: '"Choir" (Church Hall) and "Quiz" (The Pub)' }],
    source_unavailable: ["source_unavailable", { source: "Eventbrite" }]
  }.each do |kind, (key, values)|
    it "renders a #{kind} entry to its locale string" do
      report.add(kind, "#{importer}.#{key}", values:)

      expect(report.notices).to eq([I18n.t("#{importer}.#{key}", **values)])
    end
  end

  it "renders each empty-feed key to its locale string" do
    dates = { since: "8 November 2022" }
    report.add(:empty_feed, "#{importer}.feed_empty_removed", values: dates)
    report.add(:empty_feed, "#{importer}.feed_empty_no_events", values: dates)

    expect(report.notices).to eq([I18n.t("#{importer}.feed_empty_removed", **dates), I18n.t("#{importer}.feed_empty_no_events", **dates)])
  end

  it "renders a failed save as its validation messages joined with commas" do
    report.add_messages(:failed_save, ["Summary can't be blank", "Dtstart can't be blank"], uid: "a@example.com", title: "")

    expect(report.notices).to eq(["Summary can't be blank, Dtstart can't be blank"])
  end

  it "renders a location problem as its message" do
    message = I18n.t("#{importer}.room_number_without_venue")
    report.add_messages(:location_problem, [message], uid: "a@example.com", title: "Choir")

    expect(report.notices).to eq([message])
  end

  it "keeps each entry's kind and source event, in the order added", :aggregate_failures do
    report.add(:calendar_occurrence_limit, "#{importer}.calendar_occurrence_limit", values: { count: 5 })
    report.add(:occurrence_limit, "#{importer}.occurrence_limit", values: { summary: "Daily", count: 3 }, uid: "daily@example.com", title: "Daily")

    expect(report.entries.map { |entry| [entry.kind, entry.uid, entry.title] })
      .to eq([[:calendar_occurrence_limit, nil, nil], [:occurrence_limit, "daily@example.com", "Daily"]])
    expect(report.entries).to all(be_frozen)
  end

  it "has no notices when nothing was added" do
    expect(report.notices).to eq([])
  end
end
