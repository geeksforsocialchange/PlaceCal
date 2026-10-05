# frozen_string_literal: true

require "rails_helper"
require "rake"

# One-off backfill task (#3123): populate the city column on existing addresses
# by looking their postcode up via postcodes.io. We drive that real HTTP path
# with WebMock so the spec never touches the live API.
RSpec.describe "addresses:backfill_city", type: :task do
  # Load the app's rake tasks once (the guard makes repeat calls a no-op).
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  def run_task
    task = Rake::Task["addresses:backfill_city"]
    task.reenable
    task.invoke
  end

  # In test, Geocoder uses the local NormalIsland lookup; point it at the raw
  # postcodes.io lookup so we exercise (and stub) the HTTP request the task makes.
  # POSTCODES_IO_SLEEP=0 disables the politeness pause so the task runs instantly.
  around do |example|
    original = Geocoder.config.lookup
    Geocoder.configure(lookup: :postcodes_io)
    ENV["POSTCODES_IO_SLEEP"] = "0"
    example.run
  ensure
    Geocoder.configure(lookup: original)
    ENV.delete("POSTCODES_IO_SLEEP")
  end

  def stub_postcode(postcode, admin_district:)
    result = admin_district.nil? ? {} : { "admin_district" => admin_district }
    body = { "status" => 200, "result" => result }.to_json
    stub_request(:get, "https://api.postcodes.io/postcodes/#{postcode.delete(' ')}")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })
  end

  it "backfills city from the postcodes.io admin_district for NULL-city rows" do
    stub_postcode("N1 9GU", admin_district: "Islington")
    address = create(:address, city: nil, postcode: "N1 9GU")

    run_task

    expect(address.reload.city).to eq("Islington")
  end

  it "leaves addresses that already have a city untouched and makes no request" do
    address = create(:address, city: "Existing City", postcode: "N3 9GU")

    run_task

    expect(address.reload.city).to eq("Existing City")
    expect(a_request(:get, /api\.postcodes\.io/)).not_to have_been_made
  end

  it "leaves city nil when the postcode lookup returns no admin_district" do
    stub_postcode("N5 9GU", admin_district: nil)
    address = create(:address, city: nil, postcode: "N5 9GU")

    run_task

    expect(address.reload.city).to be_nil
  end
end
