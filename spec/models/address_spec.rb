# frozen_string_literal: true

require "rails_helper"

RSpec.describe Address, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:partners) }
    it { is_expected.to belong_to(:neighbourhood).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:street_address) }
    it { is_expected.to validate_presence_of(:country_code) }
    it { is_expected.to validate_presence_of(:postcode) }
  end

  describe "postcode normalization" do
    it "normalizes UK postcodes on assignment" do
      # Test normalization with valid UK postcodes (UKPostcode gem only handles UK format)
      test_address = described_class.new
      test_address.postcode = "  m15  5dd  "
      expect(test_address.postcode).to eq("M15 5DD")
    end

    it "handles various UK postcode formats" do
      address = described_class.new
      [
        ["   M15 5DD", "M15 5DD"],
        ["m155dd  ", "M15 5DD"],
        ["  M15   5DD ", "M15 5DD"],
        ["SW1A 1AA", "SW1A 1AA"]
      ].each do |input, expected|
        address.postcode = input
        expect(address.postcode).to eq(expected), "Expected '#{input}' to normalize to '#{expected}'"
      end
    end
  end

  describe "geocoding with ward" do
    context "with valid Normal Island postcode" do
      let(:address) do
        build(:address,
              street_address: "123 Main Street",
              postcode: "ZZMB 1RS",
              country_code: "ZZ")
      end

      it "is valid and assigns neighbourhood" do
        expect(address).to be_valid
        expect(address.neighbourhood).to be_present
      end

      it "sets latitude and longitude" do
        address.valid?
        expect(address.latitude).to be_present
        expect(address.longitude).to be_present
      end
    end

    context "with unknown postcode" do
      before do
        # Stub geocoder to return empty for unknown postcodes
        allow(Geocoder).to receive(:search).and_return([])
      end

      it "adds error for postcode not found" do
        # Use valid UK format postcode that passes format validation
        address = described_class.new(
          street_address: "123 Unknown Street",
          postcode: "ZZ99 9ZZ",  # Valid UK format but unknown location
          country_code: "GB"
        )
        # Manually invoke geocode validation (normally runs before_validation)
        address.valid?
        expect(address).not_to be_valid
        expect(address.errors[:postcode]).to include("was not found")
      end
    end

    context "with postcode that has no mapped neighbourhood" do
      before do
        # Stub geocoder to return a response but with unmapped ward code
        mock_data = {
          "latitude" => 50.0,
          "longitude" => -1.0,
          "codes" => { "admin_ward" => "UNMAPPED1" }
        }
        mock_result = double("GeocoderResult", data: mock_data)
        allow(Geocoder).to receive(:search).and_return([mock_result])
      end

      it "adds error for unmapped neighbourhood" do
        # Use valid UK format postcode
        address = described_class.new(
          street_address: "123 Unmapped Street",
          postcode: "ZZ11 1ZZ",  # Valid UK format
          country_code: "GB"
        )
        address.valid?
        expect(address).not_to be_valid
        expect(address.errors[:postcode]).to include("has been found but could not be mapped to a neighbourhood at this time")
      end
    end
  end

  describe "#missing_values?" do
    it "returns true when all fields are blank" do
      address = described_class.new
      expect(address.missing_values?).to be true
    end

    it "returns false when any field has value" do
      address = described_class.new(street_address: "123 Main St")
      expect(address.missing_values?).to be false
    end
  end

  describe "#full_street_address" do
    it "joins all street address lines" do
      address = build(:address,
                      street_address: "Line 1",
                      street_address2: "Line 2",
                      street_address3: "Line 3")
      expect(address.full_street_address).to eq("Line 1, Line 2, Line 3")
    end

    it "skips blank lines" do
      address = build(:address,
                      street_address: "Line 1",
                      street_address2: "",
                      street_address3: "Line 3")
      expect(address.full_street_address).to eq("Line 1, Line 3")
    end
  end

  describe "#all_address_lines" do
    it "includes all non-blank address components" do
      address = build(:riverside_address)
      lines = address.all_address_lines
      expect(lines).to include(address.street_address)
      expect(lines).to include(address.postcode)
    end
  end

  describe "#to_s" do
    it "returns comma-separated address lines" do
      address = build(:address,
                      street_address: "123 Main St",
                      city: "Millbrook",
                      postcode: "ZZMB 1RS")
      expect(address.to_s).to include("123 Main St")
      expect(address.to_s).to include("ZZMB 1RS")
    end
  end

  describe ".build_from_components" do
    before do
      create(:riverside_ward) # Ensure neighbourhood exists for geocoding
    end

    it "creates address from component array" do
      components = ["Street Line 1", "Line 2", "Line 3"]
      address = described_class.build_from_components(components, "ZZMB 1RS")
      expect(address).to be_persisted
      expect(address.street_address).to eq("Street Line 1")
      expect(address.street_address2).to eq("Line 2")
      expect(address.street_address3).to eq("Line 3")
    end

    it "returns nil for blank components" do
      expect(described_class.build_from_components(nil, "ZZMB 1RS")).to be_nil
      expect(described_class.build_from_components([], "ZZMB 1RS")).to be_nil
    end
  end

  describe ".find_by_street_or_postcode scope" do
    let!(:address1) { create(:riverside_address, street_address: "Unique Street") }
    let!(:address2) { create(:oldtown_address) }

    it "finds by street address" do
      result = described_class.find_by_street_or_postcode("Unique Street", "NONEXIST")
      expect(result).to include(address1)
    end

    it "finds by postcode" do
      result = described_class.find_by_street_or_postcode("Nonexistent", address2.postcode)
      expect(result).to include(address2)
    end
  end
end
