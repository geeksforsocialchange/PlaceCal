# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportRun do
  let(:calendar) { create(:calendar) }

  def run(outcome, started_at)
    calendar.import_runs.create!(outcome:, started_at:, finished_at: started_at + 1.minute)
  end

  describe ".prune!" do
    it "drops unchanged checks after a week and other runs after a month, but keeps each calendar's latest import" do
      latest_import = run("imported", 2.months.ago)
      old_import = run("imported", 3.months.ago)
      old_error = run("error", 5.weeks.ago)
      recent_error = run("error", 2.weeks.ago)
      old_check = run("unchanged", 8.days.ago)
      recent_check = run("unchanged", 2.days.ago)

      described_class.prune!

      expect(described_class.where(calendar:)).to contain_exactly(latest_import, recent_error, recent_check)
      expect([old_import, old_error, old_check].map { described_class.exists?(it.id) }).to all(be(false))
    end
  end

  it "closes a run left open when its calendar's stuck import is reset" do
    calendar.update_columns(calendar_state: "in_worker", import_job_id: nil, import_started_at: 2.days.ago) # rubocop:disable Rails/SkipsModelValidations
    open_run = calendar.import_runs.create!(started_at: 2.days.ago)

    Calendar.reset_stuck_imports!

    expect(open_run.reload).to have_attributes(outcome: "interrupted", finished_at: be_present)
  end
end
