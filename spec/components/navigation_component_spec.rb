# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Navigation, type: :component do
  let(:navigation) do
    [
      [I18n.t("navigation.site.home"), "/"],
      [I18n.t("navigation.site.events"), "/events"],
      [I18n.t("navigation.site.partners"), "/partners"]
    ]
  end

  it "renders navigation links" do
    render_inline(described_class.new(navigation: navigation, site: nil))

    expect(page).to have_link(I18n.t("navigation.site.events"), href: "/events")
    expect(page).to have_link(I18n.t("navigation.site.partners"), href: "/partners")
  end

  it "renders home link" do
    render_inline(described_class.new(navigation: navigation, site: nil))

    expect(page).to have_link(I18n.t("navigation.site.home"))
  end

  it "renders header structure" do
    render_inline(described_class.new(navigation: navigation, site: nil))

    expect(page).to have_css(".header")
    expect(page).to have_css("nav.nav")
  end

  # nav_region_filter (#3368): a theme opt-in, only visible once the site has
  # something to filter by. See spec/requests/public/navigation_spec.rb for
  # the same behaviour proved through a real theme registration.
  describe "the region control" do
    let(:north) { create(:partnership, name: "North") }
    let(:south) { create(:partnership, name: "South") }

    def region_enabled_theme
      theme = PlaceCal::Theme.new(:fixture)
      theme.nav_region_filter true
      theme
    end

    it "does not render when the theme setting is off" do
      Current.theme = PlaceCal::Theme.new(:fixture)
      render_inline(described_class.new(navigation: navigation, site: nil, region_tags: [north, south]))

      expect(page).not_to have_css("li.header__region")
    end

    it "does not render when the setting is on but the site has only one tag" do
      Current.theme = region_enabled_theme
      render_inline(described_class.new(navigation: navigation, site: nil, region_tags: [north]))

      expect(page).not_to have_css("li.header__region")
    end

    it "renders a segmented-control hook when the setting is on and the site has two tags" do
      Current.theme = region_enabled_theme
      render_inline(described_class.new(navigation: navigation, site: nil, region_tags: [north, south]))

      expect(page).to have_css("li.header__region nav.region-filter--nav")
      expect(page).to have_link("North")
      expect(page).to have_link("South")
    end
  end

  describe "with a region selected" do
    let(:region_navigation) do
      [
        [I18n.t("navigation.site.home"), "/?region=north"],
        [I18n.t("navigation.site.events"), "/events?region=north"],
        [I18n.t("navigation.site.partners"), "/partners?region=north"]
      ]
    end

    it "keeps the region param on every site link" do
      render_inline(described_class.new(navigation: region_navigation, site: nil))

      expect(page).to have_link(I18n.t("navigation.site.home"), href: "/?region=north")
      expect(page).to have_link(I18n.t("navigation.site.events"), href: "/events?region=north")
      expect(page).to have_link(I18n.t("navigation.site.partners"), href: "/partners?region=north")
    end
  end
end
