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
