# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "events:location_rule_changes", type: :task do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    create(:riverside_ward)
    calendar = build(:calendar, strategy: "no_location")
    calendar.save!(validate: false)
    event = build(:event, calendar:, organiser: calendar.organiser, address: nil, raw_location_from_source: "Oak Hall, 5 Elm Street, ZZMB 1RS")
    event.save!(validate: false)
  end

  def run_task(*)
    task = Rake::Task["events:location_rule_changes"]
    task.reenable
    task.invoke(*)
  end

  it "prints the text report when given no arguments" do
    expect { run_task }.to output(/Would change: 1 \(place: 0, address only: 1\).*\[address\] .*\(none\) -> Oak Hall/m).to_stdout
  end

  it "prints CSV" do
    expect { run_task("csv") }.to output(/\AEvent ID,Summary.*\n\d+,.*,\(none\),"Oak Hall, 5 Elm Street, Millbrook, ZZMB 1RS"\n\z/m).to_stdout
  end

  it "refuses an unknown format" do
    expect { run_task("xml") }.to raise_error(SystemExit).and output(/text or csv/).to_stderr
  end
end
