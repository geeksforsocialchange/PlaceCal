# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar, "when its feed changes around an import" do
  let!(:calendar) { create(:calendar, importer_mode: "ical") }

  it "does not restore the checksum of an import that ran while the feed was edited" do
    running_import = described_class.find(calendar.id)
    calendar.update!(importer_mode: "ld-json")

    running_import.flag_checksum_change!("old-feed-checksum")

    expect(calendar.reload.last_checksum).to be_nil
  end

  it "records the checksum when the feed was not edited" do
    calendar.flag_checksum_change!("new-checksum")

    expect(calendar.reload.last_checksum).to eq("new-checksum")
  end

  it "does not queue an import that another process queued after this copy was loaded", :aggregate_failures do
    stale = described_class.find(calendar.id)
    stale.update_columns(calendar_state: "idle") # rubocop:disable Rails/SkipsModelValidations
    described_class.where(id: calendar.id).update_all(calendar_state: "in_queue") # rubocop:disable Rails/SkipsModelValidations

    expect { expect(stale.queue_for_import!(true)).to be(false) }.not_to have_enqueued_job(CalendarImporterJob)
  end
end
