# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::ImportState do
  let(:calendar) { create(:calendar) }
  let(:edited_at) { 3.days.ago.change(usec: 0) }

  before do
    allow(CalendarImporterJob).to receive(:perform_later).and_return(nil)
    calendar.update_columns(updated_at: edited_at) # rubocop:disable Rails/SkipsModelValidations
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
  }.each do |method_name, (from_state, args)|
    it "#{method_name} saves without moving updated_at or switching off timestamps class-wide", :aggregate_failures do
      calendar.update_columns(calendar_state: from_state) # rubocop:disable Rails/SkipsModelValidations
      calendar.reload
      allow(Calendar).to receive(:record_timestamps=).and_call_original

      expect { calendar.public_send(method_name, *args) }.to(change { calendar.reload.attributes.except("updated_at") })
      expect(calendar.reload.updated_at).to eq(edited_at)
      expect(Calendar).not_to have_received(:record_timestamps=)
    end
  end
end
