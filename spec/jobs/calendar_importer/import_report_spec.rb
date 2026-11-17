# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::ImportReport do
  subject(:report) { described_class.new }

  let(:importer) { "admin.calendars.importer" }

  it "renders a failed save as its validation messages joined with commas" do
    report.add_messages(:failed_save, ["Summary can't be blank", "Dtstart can't be blank"], uid: "a@example.com", title: "")

    expect(report.notices).to eq(["Summary can't be blank, Dtstart can't be blank"])
  end

  it "renders a location problem as its message" do
    message = I18n.t("#{importer}.room_number_without_venue")
    report.add_messages(:location_problem, [message], uid: "a@example.com")

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
