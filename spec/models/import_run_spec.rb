# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: import_runs
#
#  id             :bigint           not null, primary key
#  error          :text
#  events_added   :integer          default(0), not null
#  events_changed :integer          default(0), not null
#  events_removed :integer          default(0), not null
#  events_skipped :integer          default(0), not null
#  finished_at    :datetime
#  importer       :string
#  notices        :jsonb            not null
#  outcome        :string
#  started_at     :datetime         not null
#  calendar_id    :bigint           not null
#
# Indexes
#
#  index_import_runs_on_calendar_id_and_started_at  (calendar_id,started_at)
#
# Foreign Keys
#
#  fk_rails_...  (calendar_id => calendars.id) ON DELETE => cascade
#
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
