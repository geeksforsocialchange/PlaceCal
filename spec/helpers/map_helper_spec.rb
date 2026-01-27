# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapHelper, type: :helper do
  describe "#style_url_for_site" do
    it "returns pink style for nil site" do
      expect(helper.send(:style_url_for_site, nil)).to eq("/map-styles/pink.json")
    end

    it "returns pink style for site with pink theme" do
      site = create(:site, theme: "pink")
      expect(helper.send(:style_url_for_site, site)).to eq("/map-styles/pink.json")
    end

    it "returns blue style for site with blue theme" do
      site = create(:site, theme: "blue")
      expect(helper.send(:style_url_for_site, site)).to eq("/map-styles/blue.json")
    end

    it "returns green style for site with green theme" do
      site = create(:site, theme: "green")
      expect(helper.send(:style_url_for_site, site)).to eq("/map-styles/green.json")
    end

    it "returns orange style for site with orange theme" do
      site = create(:site, theme: "orange")
      expect(helper.send(:style_url_for_site, site)).to eq("/map-styles/orange.json")
    end

    it "falls back to pink style for non-existent custom theme file" do
      site = create(:site, theme: "custom", slug: "nonexistent-site")
      expect(helper.send(:style_url_for_site, site)).to eq("/map-styles/pink.json")
    end

    it "accepts site slug string and looks up site" do
      site = create(:site, theme: "blue")
      expect(helper.send(:style_url_for_site, site.slug)).to eq("/map-styles/blue.json")
    end

    it "returns pink style for unknown slug string" do
      expect(helper.send(:style_url_for_site, "unknown-slug")).to eq("/map-styles/pink.json")
    end
  end

  describe "#center" do
    it "returns false for blank marker data" do
      expect(helper.send(:center, [])).to be false
      expect(helper.send(:center, nil)).to be false
    end

    it "returns single marker position for one marker" do
      markers = [{ position: [53.4668, -2.2339] }]
      expect(helper.send(:center, markers)).to eq([53.4668, -2.2339])
    end

    it "calculates average center for multiple markers" do
      markers = [
        { position: [53.0, -2.0] },
        { position: [54.0, -3.0] }
      ]
      expect(helper.send(:center, markers)).to eq([53.5, -2.5])
    end
  end

  describe "#map_style_class" do
    it "returns 'map--single' for single style mode" do
      result = helper.send(:map_style_class, [], :single, false)
      expect(result).to include("map--single")
    end

    it "returns 'map--multiple' for multi style mode" do
      result = helper.send(:map_style_class, [], :multi, false)
      expect(result).to include("map--multiple")
    end

    it "auto-detects single for one marker" do
      markers = [{ position: [53.0, -2.0] }]
      result = helper.send(:map_style_class, markers, nil, false)
      expect(result).to include("map--single")
    end

    it "auto-detects multiple for several markers" do
      markers = [
        { position: [53.0, -2.0] },
        { position: [54.0, -3.0] }
      ]
      result = helper.send(:map_style_class, markers, nil, false)
      expect(result).to include("map--multiple")
    end

    it "adds 'map--compact' when compact_mode is true" do
      result = helper.send(:map_style_class, [], :single, true)
      expect(result).to include("map--compact")
    end

    it "does not add 'map--compact' when compact_mode is false" do
      result = helper.send(:map_style_class, [], :single, false)
      expect(result).not_to include("map--compact")
    end
  end

  describe "#args_for_map" do
    let(:site) { create(:site, theme: "pink") }
    let(:map_points) do
      [
        { lat: 53.4668, lon: -2.2339, name: "Test Partner", id: "test-partner" }
      ]
    end

    it "returns valid JSON" do
      result = helper.args_for_map(map_points, site, :single, false)
      expect { JSON.parse(result) }.not_to raise_error
    end

    it "includes required keys in output" do
      result = JSON.parse(helper.args_for_map(map_points, site, :single, false))

      expect(result).to have_key("center")
      expect(result).to have_key("zoom")
      expect(result).to have_key("iconUrl")
      expect(result).to have_key("shadowUrl")
      expect(result).to have_key("markers")
      expect(result).to have_key("styleUrl")
      expect(result).to have_key("styleClass")
    end

    it "includes correct styleUrl for site theme" do
      result = JSON.parse(helper.args_for_map(map_points, site, :single, false))
      expect(result["styleUrl"]).to eq("/map-styles/pink.json")
    end

    it "includes marker positions" do
      result = JSON.parse(helper.args_for_map(map_points, site, :single, false))
      expect(result["markers"].first["position"]).to eq([53.4668, -2.2339])
    end

    it "filters out nil map points" do
      points_with_nil = [nil, map_points.first, nil]
      result = JSON.parse(helper.args_for_map(points_with_nil, site, :single, false))
      expect(result["markers"].length).to eq(1)
    end
  end
end
