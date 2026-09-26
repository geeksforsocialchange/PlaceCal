# frozen_string_literal: true

require "rails_helper"

# A site's navigation is derived from its own data (#3368 D6): there is no nav
# editor, so these are the rules that decide what a visitor sees.
RSpec.describe "Public site navigation", type: :request do
  let(:site) { create(:site, slug: "navsite") }
  let(:ward) { create(:riverside_ward) }

  before { site.neighbourhoods << ward }

  # Header nav link labels, in document order.
  def nav_labels
    Nokogiri::HTML(response.body).css("nav.header__menu ul li a").map { |a| a.text.strip }
  end

  context "with news and a contact email" do
    let(:address) { create(:address, neighbourhood: ward) }
    let(:partner) { create(:partner, address: address) }

    before do
      article = create(:article, is_draft: false)
      article.partners << partner
      site.update!(contact_email: "hello@example.com")
    end

    it "derives Home, Events, Partners, News and the join link" do
      get "http://navsite.lvh.me"

      expect(response).to be_successful
      expect(nav_labels).to eq(
        [
          I18n.t("navigation.site.home"),
          I18n.t("navigation.site.events"),
          I18n.t("navigation.site.partners"),
          I18n.t("navigation.site.news"),
          I18n.t("navigation.site.join")
        ]
      )
    end
  end

  context "with no news, no theme pages and no contact email" do
    it "renders only the core links" do
      get "http://navsite.lvh.me"

      expect(response).to be_successful
      expect(nav_labels).to eq(
        [
          I18n.t("navigation.site.home"),
          I18n.t("navigation.site.events"),
          I18n.t("navigation.site.partners")
        ]
      )
    end
  end

  # nav_region_filter (#3368): a theme opt-in, only visible once the site has
  # something to filter by.
  context "with the nav_region_filter theme setting" do
    let(:north) { create(:partnership, name: "North") }
    let(:south) { create(:partnership, name: "South") }

    def region_control
      Nokogiri::HTML(response.body).at_css("li.header__region")
    end

    it "does not render on a core theme, even with two tags", :theme_registry do
      site.tags << north
      site.tags << south

      get "http://navsite.lvh.me"

      expect(region_control).to be_nil
    end

    it "does not render when the theme opts in but the site has only one tag", :theme_registry do
      PlaceCal::Extensions.register_theme(:region_filter_fixture) { |theme| theme.nav_region_filter true }
      site.update!(theme: "region_filter_fixture")
      site.tags << north

      get "http://navsite.lvh.me"

      expect(region_control).to be_nil
    end

    it "renders as a segmented-control hook once the theme opts in and the site has two tags", :theme_registry do
      PlaceCal::Extensions.register_theme(:region_filter_fixture) { |theme| theme.nav_region_filter true }
      site.update!(theme: "region_filter_fixture")
      site.tags << north
      site.tags << south

      get "http://navsite.lvh.me"

      expect(region_control).to be_present
      expect(region_control.at_css("nav.region-filter--nav")).to be_present
      expect(region_control.css("a").map(&:text)).to include("North", "South")
    end
  end

  context "when a region is selected" do
    let(:north) { create(:partnership, name: "North") }
    let(:south) { create(:partnership, name: "South") }

    before do
      site.tags << north
      site.tags << south
      site.update!(contact_email: "hello@example.com")
    end

    # Region is sticky via links, not state (D20), and only the three links
    # that can actually be filtered carry it.
    it "carries the region on Home, Events and Partners only" do
      get "http://navsite.lvh.me?region=#{north.slug}"

      hrefs = Nokogiri::HTML(response.body).css("nav.header__menu ul li a").map { |a| a["href"] }

      expect(hrefs).to eq(
        [
          "/?region=#{north.slug}",
          "/events?region=#{north.slug}",
          "/partners?region=#{north.slug}",
          get_in_touch_path
        ]
      )
    end
  end
end
