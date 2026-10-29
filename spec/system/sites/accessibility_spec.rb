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

  # axe leaves text over a background image or under an overlapping element as incomplete rather than failing it,
  # so this measures that text against the nearest solid fill behind it. Run after be_axe_clean, which loads axe.
  UNRESOLVED_LOW_CONTRAST = <<~'JS'
    async () => {
      const luminance = (colour) => {
        const [r, g, b] = colour.match(/[\d.]+/g).slice(0, 3).map((v) => {
          v /= 255
          return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
        })
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
      }
      const fill = (el) => {
        for (; el; el = el.parentElement) {
          const bg = getComputedStyle(el).backgroundColor
          if (bg !== "transparent" && !/, 0\)$/.test(bg)) return bg
        }
        return "rgb(255, 255, 255)"
      }
      const { incomplete } = await axe.run(document, { runOnly: ["color-contrast"] })
      return incomplete.flatMap((rule) => rule.nodes)
        .filter((node) => ["bgImage", "bgOverlap"].includes(node.any[0]?.data?.messageKey))
        .flatMap((node) => {
          const el = document.querySelector(node.target[0])
          const style = getComputedStyle(el)
          const [a, b] = [luminance(style.color), luminance(fill(el))]
          const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
          const size = parseFloat(style.fontSize)
          const large = size >= 24 || (size >= 18.66 && parseInt(style.fontWeight, 10) >= 700)
          return ratio < (large ? 3 : 4.5) ? [`${ratio.toFixed(2)}:1 ${style.color} on ${fill(el)}: ${node.html}`] : []
        })
    }
  JS

  let(:ward) { create(:riverside_ward) }
  let(:outside_ward) { create(:oldtown_ward, parent: ward.parent) }
  let(:site_admin) { create(:user, first_name: "Robin", last_name: "Rivers", phone: "01234 567890") }
  let(:site) { create(:site, slug: "riverside", theme:, site_admin:) }

  let(:partner) do
    create(:partner, name: "Riverside Hub", address: create(:riverside_address, neighbourhood: ward),
                     accessibility_info: "Step-free entrance and an accessible toilet.",
                     opening_times: [{ dayOfWeek: "http://schema.org/Monday", opens: "09:00", closes: "17:00" }].to_json)
  end
  let(:outside_partner) do
    create(:partner, name: "Oldtown Hall", address: create(:oldtown_address, neighbourhood: outside_ward))
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
    create(:sites_neighbourhood, site:, neighbourhood: outside_ward, relation_type: "Secondary")
    event
    create(:event, summary: "Oldtown Social", organiser: outside_partner, address: outside_partner.address,
                   dtstart: 4.days.from_now, dtend: 4.days.from_now + 2.hours)
    article
  end

  # The site is resolved from the request host, so every visit goes to the
  # site's host on Capybara's port rather than Capybara.app_host.
  def visit_site(path)
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}#{path}"
  end

  def expect_accessible_page
    expect(page).to be_axe_clean
    expect(page.driver.with_playwright_page { |pw| pw.evaluate(UNRESOLVED_LOW_CONTRAST) }).to be_empty
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
    end
  end
end
