# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "db:find_and_clean_duplicate_events", type: :task do
  let(:calendar) { create(:calendar) }
  let(:dtstart) { 2.days.from_now.at_beginning_of_hour }
  # Rake files are loaded at the top level, so the task block's `sleep` is called on `main`
  let(:task_receiver) { TOPLEVEL_BINDING.receiver }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    allow(task_receiver).to receive(:sleep)
  end

  def run_task(*, printing: /Found/)
    task = Rake::Task["db:find_and_clean_duplicate_events"]
    task.reenable
    expect { task.invoke(*) }.to output(printing).to_stdout
  end

  # The unique index covers (calendar_id, uid, dtstart, dtend), so same-calendar duplicates differ by dtend
  def create_duplicate(uid:, dtstart:, dtend_offset:, updated_at:)
    create(:event, calendar:, uid:, dtstart:, dtend: dtstart + dtend_offset, updated_at:)
  end

  context "with two events sharing a uid and dtstart" do
    let!(:older) { create_duplicate(uid: "dupe", dtstart:, dtend_offset: 1.hour, updated_at: 2.days.ago) }
    let!(:newer) { create_duplicate(uid: "dupe", dtstart:, dtend_offset: 2.hours, updated_at: 1.day.ago) }

    it "reports the older duplicate without deleting anything" do
      run_task(printing: /dupe has duplicate count: 1 .*\n  \[#{older.id}\]/)

      expect(Event.where(id: [older.id, newer.id]).count).to eq(2)
      expect(task_receiver).not_to have_received(:sleep)
    end

    it "deletes the older duplicate and keeps the newest when told to destroy" do
      run_task("true")

      expect(Event.exists?(older.id)).to be(false)
      expect(Event.exists?(newer.id)).to be(true)
      expect(task_receiver).to have_received(:sleep).with(5)
    end
  end

  it "leaves events that share a uid on different dates alone" do
    first = create_duplicate(uid: "series", dtstart:, dtend_offset: 1.hour, updated_at: 2.days.ago)
    second = create_duplicate(uid: "series", dtstart: dtstart + 1.week, dtend_offset: 1.hour, updated_at: 1.day.ago)

    run_task("true")

    expect(Event.where(id: [first.id, second.id]).count).to eq(2)
  end

  it "leaves events without a uid alone even when they share a dtstart" do
    first = create_duplicate(uid: nil, dtstart:, dtend_offset: 1.hour, updated_at: 2.days.ago)
    second = create_duplicate(uid: nil, dtstart:, dtend_offset: 2.hours, updated_at: 1.day.ago)

    run_task("true")

    expect(Event.where(id: [first.id, second.id]).count).to eq(2)
  end
end
