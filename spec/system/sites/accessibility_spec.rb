# frozen_string_literal: true

require "rails_helper"

# Every page a visitor to a site can reach, checked with axe-core on the core design and on Trans Dimension's own.
# The core colour themes differ only in colours, so each page also has its contrast checked under every palette.
RSpec.describe "Site accessibility", :slow, type: :system do
  CORE_THEMES = PlaceCal::Extensions.themes.select(&:core?).map(&:name)
  THEMES = [CORE_THEMES.first, "transdimension"].freeze
  LISTING_PAGES = {
    "the homepage" => "/",
    "the events listing" => "/events",
    "the partners listing" => "/partners",
    "the news listing" => "/news",
    "the Get in touch page" => "/get-in-touch"
  }.freeze

  let(:ward) { create(:riverside_ward) }
  let(:second_ward) { create(:oldtown_ward, parent: ward.parent) }
  let(:site_admin) { create(:user, first_name: "Robin", last_name: "Rivers", phone: "01234 567890") }
  let(:site) { create(:site, slug: "riverside", theme:, site_admin:) }

  let(:partner) do
    create(:partner, name: "Riverside Hub", address: create(:riverside_address, neighbourhood: ward),
                     accessibility_info: "Step-free entrance and an accessible toilet.",
                     opening_times: [{ dayOfWeek: "http://schema.org/Monday", opens: "09:00", closes: "17:00" }].to_json)
  end

  let(:event) do
    create(:event, summary: "Riverside Makers", organiser: partner, address: partner.address,
                   dtstart: 3.days.from_now, dtend: 3.days.from_now + 2.hours)
  end

  let(:article) do
    create(:article, title: "Riverside Roundup", is_draft: false, published_at: 1.day.ago, partners: [partner])
  end

  # Two neighbourhoods, so listings show each partner's and event's neighbourhood pill.
  before do
    create(:sites_neighbourhood, site:, neighbourhood: ward, relation_type: "Primary")
    create(:sites_neighbourhood, site:, neighbourhood: second_ward, relation_type: "Secondary")
    event
    article
  end

  # The site is resolved from the request host, so every visit goes to the
  # site's host on Capybara's port rather than Capybara.app_host.
  def visit_site(path)
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}#{path}"
  end

  # A core theme's palette is the data-theme attribute on <html>, so the other palettes need no reload.
  def expect_accessible
    expect(page).to be_axe_clean
    return unless theme == CORE_THEMES.first

    expect(page).to have_css("html[data-theme='#{theme}']", visible: :all)
    CORE_THEMES.drop(1).each do |palette|
      page.execute_script("document.documentElement.dataset.theme = arguments[0]", palette)
      aggregate_failures("on the #{palette} palette") { expect(page).to be_axe_clean.checking_only(:"color-contrast") }
    end
  end

  THEMES.each do |theme_name|
    context "on the #{theme_name} theme" do
      let(:theme) { theme_name }

      LISTING_PAGES.each do |description, path|
        it "has no accessibility violations on #{description}" do
          visit_site(path)

          expect_accessible
        end
      end

      PlaceCal::Extensions.themes.find { |registered| registered.name == theme_name }.pages.each_key do |slug|
        it "has no accessibility violations on the theme's /#{slug} page" do
          visit_site("/#{slug}")

          expect_accessible
        end
      end

      it "has no accessibility violations on a partner page" do
        visit_site("/partners/#{partner.to_param}")

        expect_accessible
      end

      it "has no accessibility violations on an event page" do
        visit_site("/events/#{event.to_param}")

        expect_accessible
      end

      it "has no accessibility violations on an article" do
        visit_site("/news/#{article.to_param}")

        expect_accessible
      end

      context "with two partnership tags" do
        before do
          site.tags << create(:partnership, name: "North")
          site.tags << create(:partnership, name: "South")
        end

        it "has no accessibility violations on the region filter" do
          visit_site("/events")

          expect(page).to have_css("nav[data-scope='region-filter'] a[aria-current='page']")
          expect_accessible
        end

        it "has no accessibility violations on a hovered region filter option" do
          visit_site("/events")
          find("nav[data-scope='region-filter'] a", text: "North").hover

          expect_accessible
        end
      end
    end
  end
end
