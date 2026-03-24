# frozen_string_literal: true

require "rails_helper"

# Visual regression screenshot spec
#
# Captures screenshots of every public page at multiple viewports.
# Used to validate CSS changes by comparing before/after screenshots.
#
# Run via:  bin/visual-regression
# Or directly:  bundle exec rspec spec/system/visual_regression_spec.rb --order defined
#
RSpec.describe "Visual regression screenshots", :visual_regression, type: :system do
  VIEWPORTS = {
    mobile: [450, 900],
    tablet: [650, 900],
    desktop: [950, 900],
    wide: [1250, 900]
  }.freeze

  SCREENSHOT_DIR = Rails.root.join("tmp/screenshots")

  # Don't fail on missing assets — we're just capturing screenshots.
  # Uses `around` so the setting stays false through Capybara's after-hook cleanup.
  around do |example|
    original = Capybara.raise_server_errors
    Capybara.raise_server_errors = false
    example.run
  ensure
    Capybara.raise_server_errors = original
  end

  before do
    FileUtils.mkdir_p(SCREENSHOT_DIR)
  end

  def screenshot_page(name)
    VIEWPORTS.each do |label, (width, height)|
      page.driver.browser.manage.window.resize_to(width, height)
      sleep 0.3
      page.save_screenshot(SCREENSHOT_DIR.join("#{name}_#{label}.png")) # rubocop:disable Lint/Debugger
    end
  end

  # Fixed content so screenshots are deterministic across runs.
  # Faker/sequences would produce different text each time, making every diff noisy.
  FIXED_DESCRIPTION = "A welcoming space for the local community to connect, learn, and grow together."
  FIXED_BODY = "We are pleased to announce new activities and programmes for the coming months. " \
               "Our community continues to thrive thanks to the dedication of our volunteers."

  let!(:site) { create(:default_site) }

  describe "static pages" do
    it "homepage" do
      visit "/"
      screenshot_page("home")
    end

    it "find-placecal" do
      visit "/find-placecal"
      screenshot_page("find_placecal")
    end

    it "our-story" do
      visit "/our-story"
      screenshot_page("our_story")
    end

    it "privacy" do
      visit "/privacy"
      screenshot_page("privacy")
    end

    it "terms-of-use" do
      visit "/terms-of-use"
      screenshot_page("terms_of_use")
    end

    it "get-in-touch" do
      visit "/get-in-touch"
      screenshot_page("get_in_touch")
    end
  end

  describe "events" do
    let!(:partner) { create(:riverside_community_hub, description: FIXED_DESCRIPTION) }
    let!(:calendar) { create(:calendar, partner: partner) }
    let!(:event) do
      create(:event,
             partner: partner,
             calendar: calendar,
             summary: "Community Gathering",
             description: "A weekly gathering for neighbours to share food and conversation.")
    end

    it "events index" do
      visit "/events"
      screenshot_page("events_index")
    end

    it "event show" do
      visit "/events/#{event.id}"
      screenshot_page("event_show")
    end
  end

  describe "partners" do
    let!(:partner) { create(:riverside_community_hub, description: FIXED_DESCRIPTION) }

    it "partners index" do
      visit "/partners"
      screenshot_page("partners_index")
    end

    it "partner show" do
      visit "/partners/#{partner.friendly_id}"
      screenshot_page("partner_show")
    end
  end

  describe "news" do
    let!(:article) { create(:published_article, title: "Community Update", body: FIXED_BODY) }

    it "news index" do
      visit "/news"
      screenshot_page("news_index")
    end

    it "news show" do
      visit "/news/#{article.friendly_id}"
      screenshot_page("news_show")
    end
  end

  describe "collections" do
    let!(:collection) { create(:collection, name: "Winter Events", description: "Seasonal community events") }

    it "collection show" do
      visit "/collections/#{collection.id}"
      screenshot_page("collection_show")
    end
  end

  describe "partner-themed site" do
    let!(:themed_site) { create(:millbrook_site) }
    let!(:partner) { create(:riverside_community_hub, description: FIXED_DESCRIPTION) }
    let!(:calendar) { create(:calendar, partner: partner) }
    let!(:event) do
      create(:event,
             partner: partner,
             calendar: calendar,
             summary: "Millbrook Social",
             description: "A social event for the Millbrook community.")
    end

    before do
      if themed_site.neighbourhoods.any?
        partner.address.neighbourhood = themed_site.neighbourhoods.first
        partner.address.save!
      end
    end

    it "themed site homepage" do
      visit "http://#{themed_site.slug}.lvh.me:#{Capybara.current_session.server.port}/"
      screenshot_page("themed_site_home")
    end
  end
end
