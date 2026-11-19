# frozen_string_literal: true

require "rails_helper"

RSpec.describe "A calendar's default event description" do
  let(:calendar) do
    create(:ics_calendar, strategy: "no_location", importer_mode: "ical", default_description: "Details are on our Discord.")
  end

  let(:feed) do
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      UID:bare@example.com
      DTSTART:20261104T190000Z
      DTEND:20261104T200000Z
      SUMMARY:No description
      END:VEVENT
      BEGIN:VEVENT
      UID:described@example.com
      DTSTART:20261105T190000Z
      DTEND:20261105T200000Z
      SUMMARY:Described
      DESCRIPTION:Bring a friend.
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  before { Timecop.freeze(Time.zone.local(2026, 10, 29, 12)) }

  def import(force: true)
    stub_request(:get, calendar.source).to_return(status: 200, body: feed)
    calendar.update!(calendar_state: "in_worker")
    CalendarImporter::CalendarImporterTask.new(calendar, Time.current, force).run
  end

  def description_of(uid) = calendar.events.find_by!(uid:).description

  it "fills in events the feed gives no description, and leaves the others alone" do
    import

    expect(description_of("bare@example.com")).to eq("Details are on our Discord.")
    expect(description_of("described@example.com")).to eq("Bring a friend.")
  end

  it "applies a changed default at the next import, though the feed is unchanged" do
    import
    calendar.reload.update!(default_description: "Ask in the group chat.")
    import(force: false)

    expect(description_of("bare@example.com")).to eq("Ask in the group chat.")
  end
end
