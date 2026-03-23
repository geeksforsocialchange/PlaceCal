# frozen_string_literal: true

require "rails_helper"
require "csv"
require "neighbourhood_importer"

RSpec.describe NeighbourhoodImporter do
  # Suppress stdout from the importer
  before { allow($stdout).to receive(:puts) }

  describe "metropolitan county preservation" do
    let(:csv_2023) do
      CSV.generate do |csv|
        csv << %w[Empty WD23CD WD23NM WD23NMW LAD23CD LAD23NM LAD23NMW CTY23CD CTY23NM CTY23NMW RGN23CD RGN23NM RGN23NMW CTRY23CD CTRY23NM CTRY23NMW ObjectId]
        # Manchester ward → Manchester district → Greater Manchester county → North West → England
        csv << ["", "W00000001", "TestWard", "", "E08000003", "Manchester", "", "E11000001", "Greater Manchester", "", "E12000002", "North West", "", "E92000001", "England", "", "1"]
      end
    end

    let(:csv_2024) do
      CSV.generate do |csv|
        csv << %w[WD24CD WD24NM WD24NMW LAD24CD LAD24NM LAD24NMW CTYUA24CD CTYUA24NM CTYUA24NMW RGN24CD RGN24NM RGN24NMW CTRY24CD CTRY24NM CTRY24NMW ObjectId]
        # Same ward, but CTYUA = LAD (county level erased by ONS)
        csv << ["W00000001", "TestWard", "", "E08000003", "Manchester", "", "E08000003", "Manchester", "", "E12000002", "North West", "", "E92000001", "England", "", "1"]
      end
    end

    before do
      # Stub load_csv to use our test data instead of real CSV files
      allow(described_class).to receive(:load_csv).and_call_original

      # Override the run method to use our test CSVs
      described_class.instance_variable_set(:@neighbourhoods, {})
      described_class.send(:load_neighbourhoods_from_db)

      # Process 2023 CSV (has county relationship)
      stub_csv(csv_2023, DateTime.new(2023, 5), county_prefix: "CTY")
      # Process 2024 CSV (county relationship erased)
      stub_csv(csv_2024, DateTime.new(2024, 5), county_prefix: "CTYUA")

      described_class.send(:save_missing_neighbourhoods)
      described_class.send(:reparent_neighbourhoods)
      described_class.send(:backfill_levels)
      described_class.send(:update_county_release_dates)
    end

    it "preserves Manchester under Greater Manchester" do
      manchester = Neighbourhood.find_by(name: "Manchester", unit: "district")
      greater_manchester = Neighbourhood.find_by(name: "Greater Manchester", unit: "county")

      expect(manchester).to be_present
      expect(greater_manchester).to be_present
      expect(manchester.parent).to eq(greater_manchester)
    end

    it "gives Manchester the latest release date" do
      manchester = Neighbourhood.find_by(name: "Manchester", unit: "district")
      expect(manchester.release_date).to eq(DateTime.new(2024, 5))
    end

    it "bumps Greater Manchester release date to match its descendants" do
      greater_manchester = Neighbourhood.find_by(name: "Greater Manchester", unit: "county")
      expect(greater_manchester.release_date).to eq(DateTime.new(2024, 5))
    end

    it "does not reparent Manchester to the region" do
      manchester = Neighbourhood.find_by(name: "Manchester", unit: "district")
      north_west = Neighbourhood.find_by(name: "North West", unit: "region")

      expect(manchester.parent).not_to eq(north_west)
    end
  end

  describe "unitary authorities without county history" do
    let(:csv_2024) do
      CSV.generate do |csv|
        csv << %w[WD24CD WD24NM WD24NMW LAD24CD LAD24NM LAD24NMW CTYUA24CD CTYUA24NM CTYUA24NMW RGN24CD RGN24NM RGN24NMW CTRY24CD CTRY24NM CTRY24NMW ObjectId]
        # Cheshire East: CTYUA = LAD, never had a county parent
        csv << ["W00000002", "TestWard2", "", "E06000049", "Cheshire East", "", "E06000049", "Cheshire East", "", "E12000002", "North West", "", "E92000001", "England", "", "1"]
      end
    end

    before do
      described_class.instance_variable_set(:@neighbourhoods, {})
      described_class.send(:load_neighbourhoods_from_db)

      stub_csv(csv_2024, DateTime.new(2024, 5), county_prefix: "CTYUA")

      described_class.send(:save_missing_neighbourhoods)
      described_class.send(:reparent_neighbourhoods)
      described_class.send(:backfill_levels)
      described_class.send(:update_county_release_dates)
    end

    it "parents Cheshire East directly under the region" do
      cheshire = Neighbourhood.find_by(name: "Cheshire East", unit: "district")
      north_west = Neighbourhood.find_by(name: "North West", unit: "region")

      expect(cheshire).to be_present
      expect(cheshire.parent).to eq(north_west)
    end
  end

  private

  def stub_csv(csv_string, release_date, county_prefix: "CTY")
    file = Tempfile.new(["test_neighbourhoods", ".csv"])
    file.write(csv_string)
    file.rewind

    allow(Rails.root).to receive(:join).and_call_original
    allow(Rails.root).to receive(:join).with("lib/data/#{File.basename(file.path)}").and_return(file.path)

    described_class.send(:load_csv, release_date, File.basename(file.path), county_prefix: county_prefix)
  ensure
    file.close
    file.unlink
  end
end
