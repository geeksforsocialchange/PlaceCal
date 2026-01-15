# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourhoodsHelper, type: :helper do
  describe "#neighbourhood_colour" do
    it "returns correct colour for level 5 (country)" do
      expect(helper.neighbourhood_colour(5)).to eq("bg-rose-100 text-rose-700")
    end

    it "returns correct colour for level 4 (region)" do
      expect(helper.neighbourhood_colour(4)).to eq("bg-orange-100 text-orange-700")
    end

    it "returns correct colour for level 3 (county)" do
      expect(helper.neighbourhood_colour(3)).to eq("bg-emerald-100 text-emerald-700")
    end

    it "returns correct colour for level 2 (district)" do
      expect(helper.neighbourhood_colour(2)).to eq("bg-sky-100 text-sky-700")
    end

    it "returns correct colour for level 1 (ward)" do
      expect(helper.neighbourhood_colour(1)).to eq("bg-violet-100 text-violet-700")
    end

    it "returns default colour for unknown level" do
      expect(helper.neighbourhood_colour(0)).to eq("bg-gray-100 text-gray-700")
      expect(helper.neighbourhood_colour(nil)).to eq("bg-gray-100 text-gray-700")
    end

    it "accepts unit string and converts to level" do
      expect(helper.neighbourhood_colour("ward")).to eq("bg-violet-100 text-violet-700")
      expect(helper.neighbourhood_colour("country")).to eq("bg-rose-100 text-rose-700")
    end
  end

  describe "#level_badge" do
    it "renders a badge with level text" do
      result = helper.level_badge(3)
      expect(result).to include("L3")
    end

    it "applies correct colour classes" do
      result = helper.level_badge(5)
      expect(result).to include("bg-rose-100")
      expect(result).to include("text-rose-700")
    end

    it "renders with default size" do
      result = helper.level_badge(1)
      expect(result).to include("w-6 h-6")
    end

    it "renders with small size" do
      result = helper.level_badge(1, size: :small)
      expect(result).to include("w-5 h-5")
    end

    it "renders with large size" do
      result = helper.level_badge(1, size: :large)
      expect(result).to include("w-7 h-7")
    end

    it "renders with circular shape" do
      result = helper.level_badge(2)
      expect(result).to include("rounded-full")
    end
  end

  describe "#safe_neighbourhood_name" do
    let(:neighbourhood) { create(:neighbourhood, name: "Test Ward") }

    it "returns the neighbourhood name when present" do
      expect(helper.safe_neighbourhood_name(neighbourhood)).to eq("Test Ward")
    end

    it "returns placeholder when name is blank" do
      neighbourhood_blank = create(:neighbourhood, name: "temp")
      neighbourhood_blank.update_column(:name, "") # rubocop:disable Rails/SkipsModelValidations
      expect(helper.safe_neighbourhood_name(neighbourhood_blank)).to match(/\[untitled \d+\]/)
    end

    it "returns placeholder when name is nil" do
      neighbourhood_nil = create(:neighbourhood, name: "temp")
      neighbourhood_nil.update_column(:name, nil) # rubocop:disable Rails/SkipsModelValidations
      expect(helper.safe_neighbourhood_name(neighbourhood_nil)).to match(/\[untitled \d+\]/)
    end
  end
end
