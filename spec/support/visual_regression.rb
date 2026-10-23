# frozen_string_literal: true

# Settings and helpers for spec/system/visual_regression_spec.rb, run by bin/visual-regression.
module VisualRegression
  VIEWPORT_WIDTHS = [450, 950, 1250].freeze
  VIEWPORT_HEIGHT = 900
  BROWSERS = ENV.fetch("VR_BROWSERS", "chromium webkit").split.freeze
  OUTPUT_DIR = Pathname.new(ENV.fetch("VR_OUTPUT_DIR") { Rails.root.join("tmp/visual_regression/current").to_s })
  CORE_THEME = "pink"

  # Each path is evaluated in the example, so it can use the Normal Island lets.
  SITE_PAGES = {
    "home" => -> { "/" },
    "events" => -> { "/events" },
    "event" => -> { "/events/#{event_one.id}" },
    "partners" => -> { "/partners" },
    "partner" => -> { "/partners/#{riverside_hub.friendly_id}" },
    "news" => -> { "/news" },
    "article" => -> { "/news/#{vr_article.friendly_id}" }
  }.freeze

  APEX_PAGES = {
    "directory_home" => -> { vr_url(nil, "/") },
    "join_home" => -> { vr_url("join", "/") }
  }.freeze

  # Leaflet arrives from a CDN and may or may not have initialised a map by capture time, so keep only its space.
  MAP_SELECTORS = %w[[data-controller~="leaflet"] [data-controller~="cluster-map"] .leaflet-container].freeze

  SCREENSHOT_STYLE = <<~CSS.freeze
    #{MAP_SELECTORS.flat_map { |selector| [selector, "#{selector} *"] }.join(', ')} { visibility: hidden !important; }
    *, *::before, *::after { caret-color: transparent !important; }
  CSS

  # Map tiles are hidden in the screenshot, so fetching them only adds third-party requests that can stall.
  BLOCKED_REQUESTS = %r{\Ahttps?://([a-z0-9-]+\.)*(openfreemap\.org|openstreetmap\.org)/}

  # Capped waits: a stalled third-party font or image should cost a diff, not hang the run.
  LOAD_TIMEOUT_MS = 15_000
  STABLE_INTERVAL_MS = 300
  STABLE_ATTEMPTS = 5

  SETTLE_SCRIPT = <<~JS
    async () => {
      const timeout = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
      await Promise.race([document.fonts.ready, timeout(10000)]);
      document.querySelectorAll("img[loading=lazy]").forEach((img) => { img.loading = "eager"; });
      const images = [...document.images].filter((img) => !img.complete);
      await Promise.all(images.map((img) => new Promise((resolve) => {
        img.addEventListener("load", resolve, { once: true });
        img.addEventListener("error", resolve, { once: true });
        setTimeout(resolve, 5000);
      })));
      // CSS background images are not in document.images and can still be loading after a timed-out load event.
      const urls = new Set();
      for (const el of document.querySelectorAll("*")) {
        for (const pseudo of [null, "::before", "::after"]) {
          for (const match of getComputedStyle(el, pseudo).backgroundImage.matchAll(/url\\("?([^")]+)"?\\)/g)) urls.add(match[1]);
        }
      }
      await Promise.all([...urls].map((url) => Promise.race([
        new Promise((resolve) => { const img = new Image(); img.onload = img.onerror = resolve; img.src = url; }),
        timeout(5000)
      ])));
      await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    }
  JS

  # Core's pink plus every installed extension theme, so a newly installed theme is captured without editing this list.
  def self.themes
    PlaceCal::Extensions.themes.select do |theme|
      theme.name == CORE_THEME || (!theme.core? && theme.name != "example_theme")
    end
  end

  def vr_url(subdomain, path)
    host = [subdomain, "lvh.me"].compact.join(".")
    "http://#{host}:#{Capybara.current_session.server.port}#{path}"
  end

  def capture_pages(browser, prefix, pages, subdomain: nil)
    pages.each do |name, path_proc|
      path = instance_exec(&path_proc)
      url = path.start_with?("http") ? path : vr_url(subdomain, path)
      VIEWPORT_WIDTHS.each { |width| capture(url, OUTPUT_DIR.join(browser, "#{prefix}__#{name}__#{width}.png"), width) }
    end
  end

  def capture(url, file, width)
    FileUtils.mkdir_p(file.dirname)
    page.driver.with_playwright_page do |pw|
      pw.viewport_size = { width:, height: VIEWPORT_HEIGHT }
      response = pw.goto(url, waitUntil: "domcontentloaded")
      warn "visual regression: #{url} returned #{response&.status}" unless response&.ok?
      begin
        pw.wait_for_load_state(state: "load", timeout: LOAD_TIMEOUT_MS)
      rescue Playwright::TimeoutError
        warn "visual regression: #{url} did not finish loading third-party resources"
      end
      pw.evaluate(SETTLE_SCRIPT)
      File.binwrite(file, stable_screenshot(pw, url))
    end
  end

  # WebKit can paint glyphs from a system fallback font a moment after load, so wait for two identical screenshots.
  def stable_screenshot(pw_page, url)
    options = { fullPage: true, animations: "disabled", caret: "hide", style: SCREENSHOT_STYLE }
    previous = pw_page.screenshot(**options)
    STABLE_ATTEMPTS.times do
      pw_page.wait_for_timeout(STABLE_INTERVAL_MS)
      current = pw_page.screenshot(**options)
      return current if current == previous

      previous = current
    end
    warn "visual regression: #{url} was still changing after #{STABLE_ATTEMPTS} screenshots"
    previous
  end

  # The fixed clock is for Stimulus controllers, which Timecop cannot reach.
  def prepare_browser
    page.driver.with_playwright_page do |pw|
      pw.clock.set_fixed_time(Time.current.iso8601)
      pw.context.route(BLOCKED_REQUESTS, ->(route, _request) { route.abort })
    end
  end
end
