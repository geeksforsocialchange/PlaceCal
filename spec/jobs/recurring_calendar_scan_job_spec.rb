# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringCalendarScanJob, type: :job do
  it "resets stuck imports before queueing every calendar, so the same pass requeues them" do
    allow(Calendar).to receive(:reset_stuck_imports!)
    allow(Calendar).to receive(:queue_all_for_import!)

    described_class.perform_now

    expect(Calendar).to have_received(:reset_stuck_imports!).ordered
    expect(Calendar).to have_received(:queue_all_for_import!).ordered
  end
end
