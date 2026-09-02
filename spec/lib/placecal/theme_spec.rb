# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaceCal::Theme do
  subject(:theme) { described_class.new(:sample) }

  it "stores its name as a string" do
    expect(theme.name).to eq("sample")
    expect(theme.to_s).to eq("sample")
    expect(theme).not_to be_core
  end

  it "defaults every setting to nil and the date picker filter style" do
    expect(theme.stylesheet).to be_nil
    expect(theme.homepage_view).to be_nil
    expect(theme.map_style).to be_nil
    expect(theme.head).to be_nil
    expect(theme.theme_color).to be_nil
    expect(theme.event_filter_style).to eq(:date_picker)
  end

  it "sets and reads values through the DSL" do
    theme.stylesheet "sample/theme"
    theme.homepage_view "Views::Sites::Default"
    theme.map_style "sample"
    theme.head "Components::Footer"
    theme.theme_color "#f19089"
    theme.event_filter_style :day_strip

    expect(theme.stylesheet).to eq("sample/theme")
    expect(theme.homepage_view).to eq("Views::Sites::Default")
    expect(theme.map_style).to eq("sample")
    expect(theme.head).to eq("Components::Footer")
    expect(theme.theme_color).to eq("#f19089")
    expect(theme.event_filter_style).to eq(:day_strip)
  end

  it "rejects unknown event filter styles" do
    expect { theme.event_filter_style :carousel }.to raise_error(ArgumentError, /carousel/)
  end

  describe "resolution against a site" do
    let(:site) { build(:site, slug: "hulme") }

    it "returns static stylesheet and map style values" do
      theme.stylesheet "themes/pink"
      theme.map_style "pink"
      expect(theme.stylesheet_for(site)).to eq("themes/pink")
      expect(theme.map_style_for(site)).to eq("pink")
    end

    it "calls a block with the site when one was given" do
      theme.stylesheet { |s| "themes/custom/#{s.slug}" }
      theme.map_style(&:slug)
      expect(theme.stylesheet_for(site)).to eq("themes/custom/hulme")
      expect(theme.map_style_for(site)).to eq("hulme")
    end

    it "returns nil when nothing is set or the block returns nil" do
      expect(theme.stylesheet_for(site)).to be_nil
      theme.stylesheet { |_s| nil }
      expect(theme.stylesheet_for(site)).to be_nil
    end

    it "resolves view class names lazily" do
      expect(theme.homepage_view_class).to be_nil
      expect(theme.head_class).to be_nil
      theme.homepage_view "Views::Sites::Default"
      theme.head "Components::Footer"
      expect(theme.homepage_view_class).to eq(Views::Sites::Default)
      expect(theme.head_class).to eq(Components::Footer)
    end
  end

  describe "#label" do
    it "uses the locale label when present" do
      expect(described_class.new(:pink).label).to eq("Pink")
    end

    it "falls back to a titleized name" do
      expect(described_class.new(:night_sky).label).to eq("Night Sky")
    end
  end
end
