# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaceCal::Theme do
  subject(:theme) { described_class.new(:sample) }

  it "stores its name as a string" do
    expect(theme.name).to eq("sample")
    expect(theme.to_s).to eq("sample")
    expect(theme).not_to be_core
  end

  # The settings declared with `setting` in PlaceCal::Theme all behave the same
  # way, so they are asserted as a table rather than one example each.
  string_settings = %i[homepage_view head theme_color footer background_color]
  boolean_settings = { nav_join: true, menu_label: false }

  describe "declared settings" do
    string_settings.each do |name|
      it "defaults ##{name} to nil and stores what it is given as a string" do
        expect(theme.public_send(name)).to be_nil

        theme.public_send(name, :"sample-#{name}")

        expect(theme.public_send(name)).to eq("sample-#{name}")
      end
    end

    boolean_settings.each do |name, default|
      it "defaults ##{name} to #{default} and stores the opposite" do
        expect(theme.public_send(name)).to be(default)
        expect(theme.public_send(:"#{name}?")).to be(default)

        theme.public_send(name, !default)

        expect(theme.public_send(name)).to be(!default)
        expect(theme.public_send(:"#{name}?")).to be(!default)
      end
    end
  end

  it "defaults the structured settings to nil and the date picker filter style" do
    expect(theme.stylesheet).to be_nil
    expect(theme.map_style).to be_nil
    expect(theme.nav_cta).to be_nil
    expect(theme.icons).to eq({})
    expect(theme.og_image).to be_nil
    expect(theme.background_color).to be_nil
    expect(theme.event_filter_style).to eq(:date_picker)
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

    it "stores the mask icon colour alongside the paths" do
      theme.icons mask_icon: "sample/safari-pinned-tab.svg", mask_icon_color: "#FF7AA7"

      expect(theme.icons).to eq(mask_icon: "sample/safari-pinned-tab.svg", mask_icon_color: "#FF7AA7")
    end

    it "raises on an unknown key" do
      expect { theme.icons favicon_64: "sample/favicon-64x64.png" }
        .to raise_error(ArgumentError, /favicon_64/)
    end

    it "raises when the mask icon colour is an asset path rather than a colour" do
      expect { theme.icons mask_icon_color: "sample/safari-pinned-tab.svg" }
        .to raise_error(ArgumentError, /invalid mask_icon_color/)
    end
  end

  describe "#background_color" do
    it "stores the manifest background colour" do
      theme.background_color "#040f39"

      expect(theme.background_color).to eq("#040f39")
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

  it "sets and reads the block-capable and validated settings" do
    theme.stylesheet "sample/theme"
    theme.map_style "sample"
    theme.event_filter_style :day_strip

    expect(theme.stylesheet).to eq("sample/theme")
    expect(theme.map_style).to eq("sample")
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

  describe "#page" do
    it "defaults to no pages, and NONE answers the same" do
      expect(theme.pages).to eq({})
      expect(described_class::NONE.pages).to eq({})
    end

    it "records pages in registration order, frozen" do
      theme.page "about", "Sample::Views::About", nav_label_key: "sample.nav.about"
      theme.page :contact, "Sample::Views::Contact"

      expect(theme.pages).to be_frozen
      expect(theme.pages.keys).to eq(%w[about contact])
      expect(theme.pages["about"]).to eq(view: "Sample::Views::About", nav_label_key: "sample.nav.about")
      expect(theme.pages["contact"]).to eq(view: "Sample::Views::Contact", nav_label_key: nil)
    end

    it "rejects a malformed slug" do
      expect { theme.page "About Us", "Sample::Views::About" }.to raise_error(ArgumentError, /invalid page slug/)
      expect { theme.page "about/us", "Sample::Views::About" }.to raise_error(ArgumentError, /invalid page slug/)
    end

    # Core routes win over the /:slug catch-all, so a colliding slug is
    # registered and simply never served.
    it "accepts a slug a core route already owns" do
      theme.page "events", "Sample::Views::Events"

      expect(theme.pages.keys).to eq(%w[events])
    end
  end

  describe "#page_view_class" do
    it "constantizes the registered class name" do
      theme.page "about", "Components::Footer"

      expect(theme.page_view_class("about")).to eq(Components::Footer)
    end

    it "returns nil for a slug the theme does not register" do
      expect(theme.page_view_class("about")).to be_nil
    end

    it "returns nil and logs when the class name no longer resolves" do
      theme.page "about", "Nope::Views::About"
      allow(Rails.logger).to receive(:error)

      expect(theme.page_view_class("about")).to be_nil
      expect(Rails.logger).to have_received(:error).with(/page about class Nope::Views::About/)
    end
  end

  describe ".for" do
    it "returns the site's registered theme" do
      expect(described_class.for(build(:site, theme: "orange")))
        .to eq(PlaceCal::Extensions.fetch_theme("orange"))
    end

    it "returns the null theme without a site, or for a blank or unregistered theme" do
      expect(described_class.for(nil)).to eq(described_class::NONE)
      expect(described_class.for(build(:site, theme: nil))).to eq(described_class::NONE)
      expect(described_class.for(build(:site, theme: "nope"))).to eq(described_class::NONE)
    end

    it "answers every setting with its default through the null theme" do
      null = described_class.for(nil)

      expect(null.head_class).to be_nil
      expect(null.footer_class).to be_nil
      expect(null.homepage_view_class).to be_nil
      expect(null.theme_color).to be_nil
      expect(null.icons).to eq({})
      expect(null.event_filter_style).to eq(:date_picker)
      expect(null).to be_nav_join
      expect(null).not_to be_menu_label
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
