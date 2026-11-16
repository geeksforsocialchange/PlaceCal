# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostcodeLookup do
  # The test environment answers postcodes locally, so these go straight to postcodes.io with the app's other settings
  around do |example|
    Geocoder.configure(lookup: :postcodes_io)
    example.run
  ensure
    Geocoder.configure(lookup: :normal_island)
  end

  let(:postcode) { "M1 1AE" }
  let(:postcodes_io) { %r{api\.postcodes\.io/postcodes/M1(%20|\+|\s)?1AE} }

  it "returns the postcode's data" do
    stub_request(:get, postcodes_io).to_return(status: 200, headers: { "Content-Type" => "application/json" },
                                               body: { status: 200, result: { postcode: "M1 1AE", admin_district: "Manchester" } }.to_json)

    expect(described_class.call(postcode)).to include("admin_district" => "Manchester")
  end

  it "returns nil for a postcode that doesn't exist" do
    stub_request(:get, postcodes_io).to_return(status: 404, headers: { "Content-Type" => "application/json" },
                                               body: { status: 404, error: "Postcode not found" }.to_json)

    expect(described_class.call(postcode)).to be_nil
  end

  it "raises Unavailable when the service times out, instead of looking like an unknown postcode" do
    stub_request(:get, postcodes_io).to_timeout

    expect { described_class.call(postcode) }.to raise_error(described_class::Unavailable)
  end

  it "raises Unavailable when the service says it is unavailable" do
    stub_request(:get, postcodes_io).to_return(status: 503, body: "")

    expect { described_class.call(postcode) }.to raise_error(described_class::Unavailable)
  end

  it "is configured to raise outages rather than return no result" do
    expect(Geocoder.config.always_raise).to include(Geocoder::LookupTimeout, Geocoder::ServiceUnavailable)
  end

  it "gives nil from call_or_nil during an outage" do
    stub_request(:get, postcodes_io).to_timeout

    expect(described_class.call_or_nil(postcode)).to be_nil
  end
end
