# frozen_string_literal: true

require "rails_helper"

# Visual regression screenshot spec
#
# Captures full-page screenshots of every public page at multiple viewports.
# Used to validate CSS changes by comparing before/after screenshots.
#
# Run via:  bin/visual-regression
# Or directly:  VISUAL_REGRESSION=1 bundle exec rspec spec/system/visual_regression_spec.rb --order defined
#
RSpec.describe "Visual regression screenshots", :visual_regression, type: :system do
  include_context "normal island data"

  VIEWPORTS = {
    mobile: 450,
    tablet: 650,
    desktop: 950,
    wide: 1250
  }.freeze

  SCREENSHOT_DIR = Rails.root.join("tmp/screenshots")

  # Don't fail on missing assets — we're just capturing screenshots.
  around do |example|
    original = Capybara.raise_server_errors
    Capybara.raise_server_errors = false
    example.run
  ensure
    Capybara.raise_server_errors = original
  end

  before do
    FileUtils.mkdir_p(SCREENSHOT_DIR)
    Faker::Config.random = Random.new(42)
  end

  # Build a URL on a site's subdomain
  def site_url(site, path)
    port = Capybara.current_session.server.port
    "http://#{site.slug}.lvh.me:#{port}#{path}"
  end

  # Wait for images and map tiles to fully load before capturing.
  def wait_for_resources
    # Wait for all <img> elements to finish loading
    page.driver.browser.execute_async_script(<<~JS)
      var done = arguments[arguments.length - 1];
      Promise.all(
        Array.from(document.images)
          .filter(function(img) { return !img.complete; })
          .map(function(img) {
            return new Promise(function(resolve) {
              img.addEventListener('load', resolve, { once: true });
              img.addEventListener('error', resolve, { once: true });
            });
          })
      ).then(done);
    JS

    # Wait for MapLibre GL canvases to render (if any maps are on the page)
    has_maps = page.execute_script("return document.querySelectorAll('[data-controller*=leaflet]').length > 0")
    if has_maps
      # Give MapLibre GL time to load and render vector tiles
      sleep 2
    end

    # Brief settle for layout reflows after resize
    sleep 0.3
  end

  # Capture full-page screenshots at each viewport width.
  # Uses CDP to get true page dimensions and capture everything including footer.
  def screenshot_page(name)
    VIEWPORTS.each do |label, width|
      page.driver.browser.manage.window.resize_to(width, 900)
      wait_for_resources

      # Get full page dimensions via CDP
      metrics = page.driver.browser.execute_cdp("Page.getLayoutMetrics")
      full_width = metrics.dig("contentSize", "width")
      full_height = metrics.dig("contentSize", "height")

      result = page.driver.browser.execute_cdp("Page.captureScreenshot",
                                               format: "png",
                                               captureBeyondViewport: true,
                                               clip: { x: 0, y: 0, width: full_width, height: full_height, scale: 1 })
      File.binwrite(SCREENSHOT_DIR.join("#{name}_#{label}.png"), Base64.decode64(result["data"]))
    end
  end

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

  describe "site pages" do
    it "site homepage" do
      visit site_url(millbrook_site, "/")
      screenshot_page("site_home")
    end

    it "events index" do
      visit site_url(millbrook_site, "/events")
      screenshot_page("events_index")
    end

    it "event show" do
      visit site_url(millbrook_site, "/events/#{event_one.id}")
      screenshot_page("event_show")
    end

    it "partners index" do
      visit site_url(millbrook_site, "/partners")
      screenshot_page("partners_index")
    end

    it "partner show" do
      visit site_url(millbrook_site, "/partners/#{riverside_hub.friendly_id}")
      screenshot_page("partner_show")
    end

    it "news index", skip: "News not yet a supported feature" do
      visit site_url(millbrook_site, "/news")
      screenshot_page("news_index")
    end

    it "news show", skip: "News not yet a supported feature" do
      visit site_url(millbrook_site, "/news/#{article_one.friendly_id}")
      screenshot_page("news_show")
    end

    it "collection show", skip: "Collections not yet a supported feature" do
      visit site_url(millbrook_site, "/collections/#{collection.id}")
      screenshot_page("collection_show")
    end
  end
end
