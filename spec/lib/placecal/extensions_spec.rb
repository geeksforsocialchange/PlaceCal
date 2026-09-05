# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaceCal::Extensions do
  describe "boot-time registry" do
    it "contains the built-in themes plus the test fixture extension" do
      expect(described_class.theme_names).to start_with(%w[pink orange green blue custom]).and include("example_theme")
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

    it "gives each built-in theme its brand colour" do
      colors = { "pink" => "#f19089", "orange" => "#fe9263", "green" => "#afcf5a", "blue" => "#74d4ec" }
      colors.each do |name, hex|
        expect(described_class.find_theme(name).theme_color).to eq(hex)
      end
      expect(described_class.find_theme(:custom).theme_color).to be_nil
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

    it "warns when a name is re-registered outside the test environment" do
      described_class.register_theme(:sample)
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.logger).to receive(:warn)

      described_class.register_theme(:sample)

      expect(Rails.logger).to have_received(:warn).with(/"sample" was already registered/)
    end

    it "stays quiet for a first registration, and in the test environment" do
      allow(Rails.logger).to receive(:warn)
      allow(Rails.env).to receive(:test?).and_return(false)
      described_class.register_theme(:brand_new)
      allow(Rails.env).to receive(:test?).and_return(true)
      described_class.register_theme(:brand_new)

      expect(Rails.logger).not_to have_received(:warn)
    end

    it "snapshots each theme so reconfiguring a registered one cannot leak" do
      state = described_class.snapshot
      described_class.find_theme(:pink).map_style "hijacked"
      described_class.restore(state)

      expect(described_class.find_theme(:pink).map_style).to eq("pink")
    end

    it "reset! empties the registry" do
      described_class.reset!
      expect(described_class.theme_names).to be_empty
    end
  end

  # The /:slug catch-all constrains on this set, so it has to follow the
  # registry rather than be computed once at boot.
  describe ".page_slugs", :theme_registry do
    it "collects the slugs of every registered theme" do
      described_class.reset!
      described_class.register_theme(:one) { |theme| theme.page "alpha", "Sample::Views::Alpha" }
      described_class.register_theme(:two) { |theme| theme.page "beta", "Sample::Views::Beta" }

      expect(described_class.page_slugs).to eq(Set["alpha", "beta"])
    end

    it "picks up a page added after the theme was registered" do
      described_class.reset!
      described_class.register_theme(:one)
      expect(described_class.page_slugs).to be_empty

      described_class.fetch_theme(:one).page "gamma", "Sample::Views::Gamma"

      expect(described_class.page_slugs).to eq(Set["gamma"])
    end

    it "forgets slugs from a registry that has been reset or restored" do
      state = described_class.snapshot
      described_class.register_theme(:one) { |theme| theme.page "delta", "Sample::Views::Delta" }
      expect(described_class.page_slugs).to include("delta")

      described_class.restore(state)

      expect(described_class.page_slugs).not_to include("delta")
    end
  end

  describe PlaceCal::Extensions::ThemePage do
    it "matches only a slug some registered theme serves" do
      request = instance_double(ActionDispatch::Request, path_parameters: { slug: "proof" })
      expect(described_class.matches?(request)).to be true
    end

    it "does not match anything else" do
      request = instance_double(ActionDispatch::Request, path_parameters: { slug: "wp-login" })
      expect(described_class.matches?(request)).to be false
    end
  end

  it "restores the registry after a mutating example" do
    expect(described_class.theme_names).to start_with(%w[pink orange green blue custom]).and include("example_theme")
  end
end
