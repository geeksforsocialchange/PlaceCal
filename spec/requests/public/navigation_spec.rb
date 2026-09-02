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

  context "with news, an in-nav page and a contact email" do
    let(:address) { create(:address, neighbourhood: ward) }
    let(:partner) { create(:partner, address: address) }

    before do
      article = create(:article, is_draft: false)
      article.partners << partner
      create(:nav_page, site: site, title: "About", slug: "about")
      site.update!(contact_email: "hello@example.com")
    end

    it "derives Home, Events, Partners, News, the page and the join link" do
      get "http://navsite.lvh.me"

      expect(response).to be_successful
      expect(nav_labels).to eq(
        [
          I18n.t("navigation.site.home"),
          I18n.t("navigation.site.events"),
          I18n.t("navigation.site.partners"),
          I18n.t("navigation.site.news"),
          "About",
          I18n.t("navigation.site.join")
        ]
      )
    end
  end

  context "with no news, no pages and no contact email" do
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

  context "when a page is published but not in the nav" do
    before { create(:page, site: site, title: "Hidden", slug: "hidden") }

    it "leaves it out" do
      get "http://navsite.lvh.me"

      expect(nav_labels).not_to include("Hidden")
    end
  end

  context "when a region is selected" do
    let(:north) { create(:partnership, name: "North") }
    let(:south) { create(:partnership, name: "South") }

    before do
      site.tags << north
      site.tags << south
      create(:nav_page, site: site, title: "About", slug: "about")
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
          "/about",
          get_in_touch_path
        ]
      )
    end
  end
end
