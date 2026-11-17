# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "events:unlisted_venues", type: :task do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    create(:event, raw_location_from_source: "Oak Hall, ZZMB 2OT")
    create(:event, raw_location_from_source: "Elm Hall, ZZMB 3GF")
  end

  def run_task(*)
    task = Rake::Task["events:unlisted_venues"]
    task.reenable
    task.invoke(*)
  end

  it "prints the text report with the default limit when given no arguments" do
    expect { run_task }.to output(/Events at venues that match no partner: 2.*Oak Hall.*Elm Hall/m).to_stdout
  end

  it "prints CSV and applies the limit" do
    output = capture_stdout { run_task("1", "csv") }

    expect(CSV.parse(output).map { |row| row[1] }).to eq(["First line", "Oak Hall", "(no postcode)"])
  end

  it "prints CSV with the default limit when the limit is blank" do
    output = capture_stdout { run_task("", "csv") }

    expect(CSV.parse(output).length).to eq(4)
  end

  it "refuses an unknown format" do
    expect { run_task("", "xml") }.to raise_error(SystemExit).and output(/text or csv/).to_stderr
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
