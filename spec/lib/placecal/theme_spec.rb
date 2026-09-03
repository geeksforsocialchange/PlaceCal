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
    expect(theme.footer).to be_nil
    expect(theme.nav_cta).to be_nil
    expect(theme.event_filter_style).to eq(:date_picker)
    expect(theme).to be_nav_join
    expect(theme.menu_label).to be(false)
    expect(theme).not_to be_menu_label
    expect(theme.icons).to eq({})
    expect(theme.mask_icon_color).to be_nil
    expect(theme.background_color).to be_nil
    expect(theme.manifest_background_color).to be_nil
    expect(theme.og_image).to be_nil
  end

  describe "#icons" do
    it "stores the permitted icon paths" do
      theme.icons favicon_32: "sample/favicon-32x32.png",
                  favicon_16: "sample/favicon-16x16.png",
                  apple_touch_icon: "sample/apple-touch-icon.png",
                  mask_icon: "sample/safari-pinned-tab.svg",
                  icon_192: "sample/icon-192.png",
                  icon_512: "sample/icon-512.png"

      expect(theme.icons).to eq(
        favicon_32: "sample/favicon-32x32.png",
        favicon_16: "sample/favicon-16x16.png",
        apple_touch_icon: "sample/apple-touch-icon.png",
        mask_icon: "sample/safari-pinned-tab.svg",
        icon_192: "sample/icon-192.png",
        icon_512: "sample/icon-512.png"
      )
    end

    it "accepts a subset of the keys" do
      theme.icons favicon_32: "sample/favicon-32x32.png"

      expect(theme.icons).to eq(favicon_32: "sample/favicon-32x32.png")
    end

    it "drops blank paths" do
      theme.icons favicon_32: "sample/favicon-32x32.png", favicon_16: nil

      expect(theme.icons).to eq(favicon_32: "sample/favicon-32x32.png")
    end

    it "raises on an unknown key" do
      expect { theme.icons favicon_64: "sample/favicon-64x64.png" }
        .to raise_error(ArgumentError, /favicon_64/)
    end
  end

  describe "#mask_icon_color" do
    it "stores the colour as a string" do
      theme.mask_icon_color "#FF7AA7"

      expect(theme.mask_icon_color).to eq("#FF7AA7")
    end
  end

  describe "#background_color" do
    it "stores the manifest background colour" do
      theme.background_color "#040f39"

      expect(theme.background_color).to eq("#040f39")
      expect(theme.manifest_background_color).to eq("#040f39")
    end

    it "falls back to the theme colour when unset" do
      theme.theme_color "#ff7aa7"

      expect(theme.background_color).to be_nil
      expect(theme.manifest_background_color).to eq("#ff7aa7")
    end
  end

  describe "#og_image" do
    it "stores the path with its dimensions" do
      theme.og_image "sample/og.png", width: 1200, height: 675

      expect(theme.og_image).to eq(path: "sample/og.png", width: 1200, height: 675)
    end

    it "allows dimensions to be omitted" do
      theme.og_image "sample/og.png"

      expect(theme.og_image).to eq(path: "sample/og.png", width: nil, height: nil)
    end
  end

  it "lets a theme label the mobile menu toggle" do
    theme.menu_label true

    expect(theme.menu_label).to be(true)
    expect(theme).to be_menu_label
  end

  it "lets a theme drop the Join link from the main nav" do
    theme.nav_join false

    expect(theme.nav_join).to be(false)
    expect(theme).not_to be_nav_join
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
      mossley = build(:site, slug: "mossley")
      theme.stylesheet { |s| "themes/custom/#{s.slug}" }
      theme.map_style(&:slug)
      expect(theme.stylesheet_for(mossley)).to eq("themes/custom/mossley")
      expect(theme.map_style_for(site)).to eq("hulme")
    end

    it "returns nil and logs when the stylesheet is missing from the pipeline" do
      allow(Rails.logger).to receive(:error)
      theme.stylesheet "themes/no-such-theme"

      expect(theme.stylesheet_for(site)).to be_nil
      expect(Rails.logger).to have_received(:error).with(%r{themes/no-such-theme\.css})
    end

    it "returns nil and logs when a block resolves to a missing stylesheet" do
      allow(Rails.logger).to receive(:error)
      theme.stylesheet { |s| "themes/custom/#{s.slug}" }

      expect(theme.stylesheet_for(site)).to be_nil
      expect(Rails.logger).to have_received(:error).with(%r{themes/custom/hulme\.css})
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

    it "returns nil and logs when a class name no longer resolves" do
      theme.homepage_view "Nope::Views::Home"
      theme.head "Nope::Components::Head"
      theme.footer "Nope::Components::Footer"

      allow(Rails.logger).to receive(:error)

      expect(theme.homepage_view_class).to be_nil
      expect(theme.head_class).to be_nil
      expect(theme.footer_class).to be_nil

      expect(Rails.logger).to have_received(:error).with(/homepage_view class Nope::Views::Home/)
      expect(Rails.logger).to have_received(:error).with(/head class Nope::Components::Head/)
      expect(Rails.logger).to have_received(:error).with(/footer class Nope::Components::Footer/)
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
