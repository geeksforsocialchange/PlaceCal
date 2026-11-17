# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261117150100_hand_queued_imports_to_solid_queue.rb")

RSpec.describe HandQueuedImportsToSolidQueue do
  before { ActiveRecord::Migration.verbose = false }

  def calendar_in(state, job_id)
    create(:calendar).tap { it.update_columns(calendar_state: state, import_job_id: job_id) } # rubocop:disable Rails/SkipsModelValidations
  end

  it "sets queued and importing calendars to idle, keeps other states, and forgets every delayed_job id" do
    calendars = { "in_queue" => calendar_in("in_queue", 1), "in_worker" => calendar_in("in_worker", 2),
                  "error" => calendar_in("error", 3), "bad_source" => calendar_in("bad_source", 4), "idle" => calendar_in("idle", 5) }

    described_class.new.up

    expect(calendars.transform_values { it.reload.calendar_state }).to eq(
      "in_queue" => "idle", "in_worker" => "idle", "error" => "error", "bad_source" => "bad_source", "idle" => "idle"
    )
    expect(calendars.values.map(&:import_job_id)).to all(be_nil)
  end
end
