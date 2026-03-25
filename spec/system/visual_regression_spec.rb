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

  # false: visit once per url, resize for each size. faster
  # true: visit once per size. slower but helps with map rendering and layout aliasing
  # run with `clean` afterr changing this value
  VISIT_PER_SIZE = false

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
  def wait_for_resources(name, label = nil)
    # Wait for `load` event and all maps to have a size
    output = page.driver.browser.execute_async_script(<<~JS)
      const TIMEOUT_MS = 5_000;
      // promise resolver provided by selenium
      const [done] = arguments;
      const started = Date.now();
      const { readyState } = document;
      let readyStateTimeout = false;
      let mapResult = null;

      // wait for `load` event if not already fired
      if (readyState !== 'complete')
        await new Promise((resolve) => {
          document.addEventListener('load', resolve, { once: true })
          setTimeout(() => {
            readyStateTimeout = true;
            resolve();
          }, TIMEOUT_MS);
        });

      // wait for all maps to have a size. ideally we'd wait for an event (maybe a debounced TileEvent) from each map but getting an object ref from the js controller would be difficult
      // https://leafletjs.com/reference.html#event-objects
      const maps = document.querySelectorAll('[data-controller="leaflet"]');
      if (maps.length)
        mapResult = await new Promise((resolve) => {
          setTimeout(() => resolve('timeout'), TIMEOUT_MS);
          function resolveIfAllSized(reason){
            for (const map of maps) {
              const bounds = map.getBoundingClientRect();
              if (bounds.width < 1 || bounds.height < 1) return false;
            };
            resolve(reason);
            return true;
          }
          if (resolveIfAllSized('initial')) return;
          const observer = new ResizeObserver(() => resolveIfAllSized('observed'));
          for (const map of maps) observer.observe(map);
        })

      const elapsed = (Date.now() - started) / 1000;
      /** @type {{ readyState: 'loading' | 'interactive' | 'complete', mapResult: null | 'initial' | 'observed' | 'timeout', elapsed: number}} */
      done({ readyState, mapResult, elapsed });
    JS

    return
    # rubocop: disable Lint/UnreachableCode
    # rubocop: disable RSpec/Output
    if label
      puts "#{name}, #{label}: #{output}"
    else
      puts "#{name}: #{output}"
    end
    # rubocop: enable RSpec/Output
    # rubocop: enable Lint/UnreachableCode
  end

  # Capture full-page screenshots at each viewport width.
  # Uses CDP to get true page dimensions and capture everything including footer.
  def screenshot_page(url, name)
    unless VISIT_PER_SIZE
      visit(url)
      wait_for_resources(name)
    end

    VIEWPORTS.each do |label, width|
      page.driver.browser.manage.window.resize_to(width, 900)
      if VISIT_PER_SIZE
        visit(url)
        # resize_to before a visit is more correct but seems unreliable
        page.driver.browser.manage.window.resize_to(width, 900)
        wait_for_resources(name, width)
      else
        sleep 0.3
      end

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
      screenshot_page("/", "home")
    end

    it "find-placecal" do
      screenshot_page("/find-placecal", "find_placecal")
    end

    it "our-story" do
      screenshot_page("/our-story", "our_story")
    end

    it "privacy" do
      screenshot_page("/privacy", "privacy")
    end

    it "terms-of-use" do
      screenshot_page("/terms-of-use", "terms_of_use")
    end

    it "get-in-touch" do
      screenshot_page("/get-in-touch", "get_in_touch")
    end
  end

  describe "site pages" do
    it "site homepage" do
      screenshot_page(site_url(millbrook_site, "/"), "site_home")
    end

    it "events index" do
      screenshot_page(site_url(millbrook_site, "/events"), "events_index")
    end

    it "event show" do
      screenshot_page(site_url(millbrook_site, "/events/#{event_one.id}"), "event_show")
    end

    it "partners index" do
      screenshot_page(site_url(millbrook_site, "/partners"), "partners_index")
    end

    it "partner show" do
      screenshot_page(site_url(millbrook_site, "/partners/#{riverside_hub.friendly_id}"), "partner_show")
    end

    it "news index", skip: "News not yet a supported feature" do
      screenshot_page(site_url(millbrook_site, "/news"), "news_index")
    end

    it "news show", skip: "News not yet a supported feature" do
      screenshot_page(site_url(millbrook_site, "/news/#{article_one.friendly_id}"), "news_show")
    end

    it "collection show", skip: "Collections not yet a supported feature" do
      screenshot_page(site_url(millbrook_site, "/collections/#{collection.id}"), "collection_show")
    end
  end
end
