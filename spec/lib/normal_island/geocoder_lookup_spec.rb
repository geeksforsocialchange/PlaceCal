# frozen_string_literal: true

require "rails_helper"

# Regression coverage for issue #2991: adding/editing a partner using the
# seeded dev database raised "uninitialized constant NormalIsland" because the
# geocoder initializer required the custom lookup but never loaded the
# NormalIsland data module it depends on (POSTCODES, WARDS, ADDRESSES, ...).
#
# Note: factories in spec/factories/normal_island load the NormalIsland module
# at suite boot, so a plain `Geocoder.search` would always pass under RSpec and
# would NOT catch a regression. We therefore also assert that the geocoder
# initializer itself loads the module, which is the guarantee the running
# (factory-free) app relies on.
RSpec.describe Geocoder::Lookup::NormalIsland do
  it "loads the NormalIsland data module from the geocoder initializer" do
    initializer = Rails.root.join("config/initializers/geocoder.rb").read

    expect(initializer).to include("require 'normal_island'")
  end

  it "resolves the NormalIsland constant when looking up a Normal Island postcode" do
    expect { described_class.new.search("ZZMB 1RS") }.not_to raise_error
  end

  it "returns the seeded Normal Island result for a known postcode" do
    results = described_class.new.search("ZZMB 1RS")

    expect(results.size).to eq(1)
    expect(results.first.coordinates).to eq([53.5, -1.5])
    expect(results.first.data["admin_ward"]).to eq("Riverside")
  end
end
