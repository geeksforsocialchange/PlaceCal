# frozen_string_literal: true

require "rails_helper"

RSpec.describe SelfRescheduling do
  describe "#run" do
    it "re-enqueues the job after successful execution" do
      setter = double("setter")
      allow(RecurringCalendarScanJob).to receive(:set)
        .with(wait: RecurringCalendarScanJob::INTERVAL).and_return(setter)
      allow(setter).to receive(:perform_later)
      allow(Calendar).to receive(:queue_all_for_import!)

      RecurringCalendarScanJob.perform_now

      expect(setter).to have_received(:perform_later)
    end

    it "does not re-enqueue when the block raises (DJ handles retry)" do
      setter = double("setter")
      allow(RecurringMaintenanceJob).to receive(:set).and_return(setter)
      allow(setter).to receive(:perform_later)
      allow(Event).to receive(:deduplicate!).and_raise("boom")

      expect { RecurringMaintenanceJob.perform_now }.to raise_error("boom")
      expect(setter).not_to have_received(:perform_later)
    end

    it "retries re-enqueue on transient failure" do
      call_count = 0
      setter = double("setter")
      allow(RecurringCalendarScanJob).to receive(:set).and_return(setter)
      allow(setter).to receive(:perform_later) do
        call_count += 1
        raise ActiveRecord::ConnectionNotEstablished if call_count == 1
      end
      allow(Calendar).to receive(:queue_all_for_import!)
      allow_any_instance_of(RecurringCalendarScanJob).to receive(:sleep)

      RecurringCalendarScanJob.perform_now

      expect(call_count).to eq(2)
    end

    it "logs error after exhausting reschedule attempts" do
      setter = double("setter")
      allow(RecurringCalendarScanJob).to receive(:set).and_return(setter)
      allow(setter).to receive(:perform_later)
        .and_raise(ActiveRecord::ConnectionNotEstablished)
      allow(Calendar).to receive(:queue_all_for_import!)
      allow_any_instance_of(RecurringCalendarScanJob).to receive(:sleep)
      allow(Rails.logger).to receive(:error)

      RecurringCalendarScanJob.perform_now

      expect(Rails.logger).to have_received(:error)
        .with(/Failed to reschedule after 3 attempts/)
    end
  end
end

RSpec.describe RecurringWatchdogJob, type: :job do
  describe "#perform" do
    before do
      setter = double("setter")
      allow(described_class).to receive(:set).and_return(setter)
      allow(setter).to receive(:perform_later)
    end

    it "does nothing when all jobs are present" do
      allow(Delayed::Job).to receive(:exists?).and_return(true)
      allow(RecurringCalendarScanJob).to receive(:perform_later)
      allow(RecurringMaintenanceJob).to receive(:perform_later)

      described_class.perform_now

      expect(RecurringCalendarScanJob).not_to have_received(:perform_later)
      expect(RecurringMaintenanceJob).not_to have_received(:perform_later)
    end

    it "re-seeds a missing calendar scan job" do
      allow(Delayed::Job).to receive(:exists?)
        .with(["handler LIKE ?", "%RecurringCalendarScanJob%"]).and_return(false)
      allow(Delayed::Job).to receive(:exists?)
        .with(["handler LIKE ?", "%RecurringMaintenanceJob%"]).and_return(true)
      allow(RecurringCalendarScanJob).to receive(:perform_later)
      allow(RecurringMaintenanceJob).to receive(:perform_later)

      described_class.perform_now

      expect(RecurringCalendarScanJob).to have_received(:perform_later)
      expect(RecurringMaintenanceJob).not_to have_received(:perform_later)
    end

    it "re-seeds both jobs when both are missing" do
      allow(Delayed::Job).to receive(:exists?).and_return(false)
      allow(RecurringCalendarScanJob).to receive(:perform_later)
      allow(RecurringMaintenanceJob).to receive(:perform_later)

      described_class.perform_now

      expect(RecurringCalendarScanJob).to have_received(:perform_later)
      expect(RecurringMaintenanceJob).to have_received(:perform_later)
    end
  end
end
