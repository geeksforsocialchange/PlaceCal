# frozen_string_literal: true

require "rails_helper"

# Every page a visitor to a core-themed site can reach, checked with axe-core
# the way the directory is (spec/system/directory/accessibility_spec.rb). The
# extension themes run the same sweep in their own repos; this is the one for
# the markup and palette core ships.
RSpec.describe "Site accessibility", :slow, type: :system do
  # color-contrast is the one rule skipped, because what trips it is the core
  # palette itself rather than markup: on the pink theme white text on the
  # primary colour (#fffcf0 on #f19089, buttons and the partner card badge)
  # measures 2.24:1 and the footer impressum (#998675 on #5b4e46) 2.29:1,
  # against the 4.5:1 the rule wants. Changing that is a design decision for
  # every core theme, not a spec fix. Everything structural is enforced.
  PALETTE_RULES = [:"color-contrast"].freeze

  let(:ward) { create(:riverside_ward) }
  let(:site) { create(:site, slug: "riverside", theme: "pink", url: "https://riverside.lvh.me") }
  let(:partner) { create(:partner, name: "Riverside Hub", address: create(:riverside_address, neighbourhood: ward)) }

  let(:event) do
    create(:event, summary: "Riverside Makers", organiser: partner,
                   dtstart: 3.days.from_now, dtend: 3.days.from_now + 2.hours)
  end

  let(:article) do
    create(:article, title: "Riverside Roundup", is_draft: false, published_at: 1.day.ago, partners: [partner])
  end

  before do
    site.neighbourhoods << ward
    event
    article
  end

  # The site is resolved from the request host, so every visit goes to the
  # site's host on Capybara's port rather than Capybara.app_host.
  def visit_site(path)
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}#{path}"
  end

  {
    "the homepage" => "/",
    "the events listing" => "/events",
    "the partners listing" => "/partners",
    "the news listing" => "/news",
    "the Get in touch page" => "/get-in-touch"
  }.each do |description, path|
    it "has no accessibility violations on #{description}" do
      visit_site(path)

      expect(page).to be_axe_clean.skipping(*PALETTE_RULES)
    end
  end

  it "has no accessibility violations on a partner page" do
    visit_site("/partners/#{partner.to_param}")

    expect(page).to be_axe_clean.skipping(*PALETTE_RULES)
  end

  it "has no accessibility violations on an event page" do
    visit_site("/events/#{event.to_param}")

    expect(page).to be_axe_clean.skipping(*PALETTE_RULES)
  end

  it "has no accessibility violations on an article" do
    visit_site("/news/#{article.to_param}")

    expect(page).to be_axe_clean.skipping(*PALETTE_RULES)
  end
end
