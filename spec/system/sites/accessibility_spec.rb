# frozen_string_literal: true

require "rails_helper"

# Every page a visitor to a core-themed site can reach, checked with axe-core
# on each core colour theme, so the palette is held to contrast as well as the markup.
RSpec.describe "Site accessibility", :slow, type: :system do
  CORE_THEMES = PlaceCal::Extensions.themes.select(&:core?).map(&:name)
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

  def expect_accessible_page
    expect(page).to be_axe_clean
    expect(page).to have_no_unresolved_low_contrast
  end

  CORE_THEMES.each do |core_theme|
    context "on the #{core_theme} theme" do
      let(:theme) { core_theme }

      LISTING_PAGES.each do |description, path|
        it "has no accessibility violations on #{description}" do
          visit_site(path)

          expect_accessible_page
        end
      end

      it "has no accessibility violations on a partner page" do
        visit_site("/partners/#{partner.to_param}")

        expect_accessible_page
      end

      it "has no accessibility violations on an event page" do
        visit_site("/events/#{event.to_param}")

        expect_accessible_page
      end

      it "has no accessibility violations on an article" do
        visit_site("/news/#{article.to_param}")

        expect_accessible_page
      end

      context "with two partnership tags" do
        before do
          site.tags << create(:partnership, name: "North")
          site.tags << create(:partnership, name: "South")
        end

        it "has no accessibility violations on the region filter" do
          visit_site("/events")

          expect(page).to have_css("nav.region-filter a[aria-current='page']", text: "All")
          expect_accessible_page
        end

        it "has no accessibility violations on a hovered region filter option" do
          visit_site("/events")
          find("nav.region-filter a", text: "North").hover

          expect_accessible_page
        end
      end
    end
  end
end
