# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::ImportState do
  let(:calendar) { create(:calendar) }

  before do
    allow(CalendarImporterJob).to receive(:perform_later).and_return(nil)
    calendar.update_columns(updated_at: 3.days.ago) # rubocop:disable Rails/SkipsModelValidations
  end

  {
    queue_for_import!: [:idle, [false]],
    flag_start_import_job!: [:in_queue, []],
    flag_complete_import_job!: [:in_worker, [["A notice"], "ical"]],
    flag_skipped_import_job!: [:in_worker, [["Skipped"]]],
    flag_feed_empty!: [:idle, [true]],
    flag_checksum_change!: [:idle, ["abc123"]],
    flag_bad_source!: [:in_worker, ["Not found"]],
    flag_error_import_job!: [:in_worker, ["Broken"]]
  }.each do |change, (from_state, args)|
    it "#{change} saves without moving updated_at or switching off timestamps class-wide", :aggregate_failures do
      calendar.update_columns(calendar_state: from_state) # rubocop:disable Rails/SkipsModelValidations
      calendar.reload
      allow(Calendar).to receive(:record_timestamps=).and_call_original

      expect { calendar.public_send(change, *args) }.to(change { calendar.reload.attributes.except("updated_at") })
      expect(calendar.reload.updated_at).to be_within(1.second).of(3.days.ago)
      expect(Calendar).not_to have_received(:record_timestamps=)
    end
  end
end
