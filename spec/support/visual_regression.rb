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

  # Maps load third-party tiles at their own pace, so the screenshot shows only the map's box.
  SCREENSHOT_STYLE = <<~CSS
    [data-controller~="leaflet"] * { visibility: hidden !important; }
    *, *::before, *::after { caret-color: transparent !important; }
  CSS

  SETTLE_SCRIPT = <<~JS
    async () => {
      await document.fonts.ready;
      const images = [...document.images].filter((img) => !img.complete);
      await Promise.all(images.map((img) => new Promise((resolve) => {
        img.addEventListener("load", resolve, { once: true });
        img.addEventListener("error", resolve, { once: true });
        setTimeout(resolve, 5000);
      })));
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
      response = pw.goto(url, waitUntil: "load")
      warn "visual regression: #{url} returned #{response&.status}" unless response&.ok?
      pw.evaluate(SETTLE_SCRIPT)
      pw.screenshot(path: file.to_s, fullPage: true, animations: "disabled", caret: "hide", style: SCREENSHOT_STYLE)
    end
  end

  # Stimulus controllers read the browser clock, which Timecop cannot reach.
  def freeze_browser_clock
    page.driver.with_playwright_page { |pw| pw.clock.set_fixed_time(Time.current.iso8601) }
  end
end
