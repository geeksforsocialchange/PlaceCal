# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaceCal::Extensions do
  describe "boot-time registry" do
    it "contains the built-in themes plus the test fixture extension" do
      expect(described_class.theme_names).to eq(%w[pink orange green blue custom example_theme])
    end

    it "lists built-in themes as core" do
      expect(described_class.themes.select(&:core?).map(&:name)).to eq(%w[pink orange green blue custom])
      expect(described_class.find_theme(:example_theme)).not_to be_core
    end

    it "resolves built-in stylesheets and map styles" do
      site = build(:site, slug: "hulme")
      pink = described_class.find_theme(:pink)
      expect(pink.stylesheet_for(site)).to eq("themes/pink")
      expect(pink.map_style_for(site)).to eq("pink")
      expect(pink.homepage_view_class).to be_nil
    end

    it "resolves the legacy custom theme by site slug" do
      custom = described_class.find_theme(:custom)
      site = build(:site, slug: "mossley")
      expect(custom.map_style_for(site)).to eq("mossley")
      resolver = Rails.application.assets.resolver
      allow(resolver).to receive(:resolve).with("themes/custom/mossley.css").and_return("/assets/themes/custom/mossley-abc.css")
      expect(custom.stylesheet_for(site)).to eq("themes/custom/mossley")
      allow(resolver).to receive(:resolve).with("themes/custom/mossley.css").and_return(nil)
      expect(custom.stylesheet_for(site)).to be_nil
    end
  end

  describe "mutation", :theme_registry do
    it "registers a theme and yields it for configuration" do
      theme = described_class.register_theme(:sample) { |t| t.stylesheet "sample/theme" }
      expect(theme).to be_a(PlaceCal::Theme)
      expect(described_class.theme_names).to include("sample")
      expect(described_class.find_theme("sample").stylesheet).to eq("sample/theme")
    end

    it "replaces an existing registration with the same name" do
      described_class.register_theme(:sample) { |t| t.map_style "one" }
      described_class.register_theme(:sample) { |t| t.map_style "two" }
      expect(described_class.theme_names.count("sample")).to eq(1)
      expect(described_class.find_theme(:sample).map_style).to eq("two")
    end

    it "orders core themes before extension themes regardless of registration order" do
      described_class.reset!
      described_class.register_theme(:ext)
      described_class.register_theme(:pink, core: true)
      expect(described_class.theme_names).to eq(%w[pink ext])
    end

    it "finds themes by symbol or string and returns nil for unknown or blank" do
      expect(described_class.find_theme(:pink)).to eq(described_class.find_theme("pink"))
      expect(described_class.find_theme(:nope)).to be_nil
      expect(described_class.find_theme(nil)).to be_nil
      expect(described_class.find_theme("")).to be_nil
    end

    it "raises from fetch_theme for unknown names" do
      expect { described_class.fetch_theme(:nope) }.to raise_error(PlaceCal::Extensions::UnknownTheme, /nope/)
    end

    it "reset! empties the registry" do
      described_class.reset!
      expect(described_class.theme_names).to be_empty
    end
  end

  it "restores the registry after a mutating example" do
    expect(described_class.theme_names).to eq(%w[pink orange green blue custom example_theme])
  end
end
