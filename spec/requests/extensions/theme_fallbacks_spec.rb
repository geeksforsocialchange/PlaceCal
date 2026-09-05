# frozen_string_literal: true

require "rails_helper"

# Homepage view for the content_for(:theme_head) fallback case: a theme with no
# registered head component whose view pushes its own markup into <head>.
class ThemeHeadFallbackHome < Views::Base
  prop :site, _Nilable(Site), reader: :private

  def view_template
    content_for(:theme_head) do
      meta(name: "theme-head-fallback", content: "pushed")
    end
    h1 { "Fallback theme homepage" }
  end
end

# WP 3.1 (#3368): what core does when a theme fills a slot badly or not at all.
# A missing stylesheet or view class must not take a site down, an unset slot
# must fall back to core's own, and a theme with no head component can still
# push markup into <head> through content_for.
RSpec.describe "Theme fallbacks", :theme_registry, type: :request do
  let(:ward) { create(:riverside_ward) }

  def site_on(theme, slug)
    site = create(:site, slug: slug, theme: theme, url: "https://#{slug}.lvh.me")
    site.neighbourhoods << ward
    site
  end

  def head_html
    response.body[%r{<head>.*?</head>}m]
  end

  context "with a theme whose stylesheet and classes are missing" do
    let(:site) { site_on("brokenly", "brokenly") }

    before do
      PlaceCal::Extensions.register_theme(:brokenly) do |theme|
        theme.stylesheet "brokenly/theme"
        theme.homepage_view "Brokenly::Views::Home"
        theme.head "Brokenly::Components::Head"
        theme.footer "Brokenly::Components::Footer"
      end
      allow(Rails.logger).to receive(:warn)
      # The theme must be registered before the site is validated.
      site
    end

    it "renders the site homepage without the missing stylesheet" do
      get "http://brokenly.lvh.me"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("brokenly/theme")
      expect(response.body).to include(site.description)
      expect(Rails.logger).to have_received(:warn).with(%r{brokenly/theme\.css})
    end

    it "renders an inner page without the missing head and footer components" do
      get "http://brokenly.lvh.me/news"

      expect(response).to have_http_status(:ok)
      expect(Rails.logger).to have_received(:warn).with(/head class Brokenly::Components::Head/)
    end
  end

  context "with a theme that sets no colours or icons" do
    before do
      PlaceCal::Extensions.register_theme(:bare_theme)
      site_on("bare_theme", "barely")
    end

    it "emits no theme-color meta and keeps core's icons" do
      get "http://barely.lvh.me"

      expect(response).to have_http_status(:ok)
      head = head_html
      expect(head).not_to include('name="theme-color"')
      expect(head).to match(%r{<link rel="icon" type="image/png" href="[^"]*/assets/favicon-[0-9a-f]+\.png">})
    end

    it "falls back to core's manifest colours and icons" do
      get "http://barely.lvh.me/manifest.webmanifest"

      manifest = JSON.parse(response.body)
      expect(manifest["theme_color"]).to eq("#f19089")
      expect(manifest["background_color"]).to eq("#f19089")
      expect(manifest["icons"].map { |i| i["sizes"] }).to eq(%w[64x64 180x180])
    end
  end

  # Theme pages (theme.page): core serves /:slug only when the current site's
  # theme registers that slug and its view class resolves.
  context "with theme pages" do
    before do
      site_on("example_theme", "themed")
      site_on("pink", "plain")
    end

    # The catch-all is constrained to slugs some registered theme serves
    # (PlaceCal::Extensions::ThemePage), so an unknown path is a routing 404
    # rather than a fully rendered one: nothing runs the public filter chain
    # for a scanner walking /wp-login and friends.
    it "does not route a slug no registered theme serves" do
      expect { get "http://themed.lvh.me/nothing-here" }
        .to raise_error(ActionController::RoutingError)
    end

    # Bare paths only: an explicit format would otherwise serve the HTML page
    # under the wrong content type.
    it "does not route a theme page with an explicit format" do
      expect { get "http://themed.lvh.me/proof.json" }
        .to raise_error(ActionController::RoutingError)
      expect { get "http://themed.lvh.me/proof.html" }
        .to raise_error(ActionController::RoutingError)
    end

    it "404s for a theme page slug on a site whose theme is core's" do
      get "http://plain.lvh.me/proof"

      expect(response).to have_http_status(:not_found)
    end

    it "404s on the nationwide directory, which has no site and so no theme" do
      get "http://lvh.me/proof"

      expect(response).to have_http_status(:not_found)
    end

    it "404s when the registered view class no longer resolves" do
      PlaceCal::Extensions.register_theme(:pagey) do |theme|
        theme.page "about", "Nope::Views::About"
      end
      site_on("pagey", "pagey")
      allow(Rails.logger).to receive(:warn)

      get "http://pagey.lvh.me/about"

      expect(response).to have_http_status(:not_found)
      expect(Rails.logger).to have_received(:warn).with(/page about class Nope::Views::About/)
    end

    it "falls back to core's privacy page when the theme registers none" do
      get "http://themed.lvh.me/privacy"

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/privacy/i)
      expect(response.body).not_to include("Example theme fixture proof page")
    end
  end

  # A theme's icon and share-image paths are asset logical paths resolved with
  # image_url, which raises when the asset is gone. A bumped engine gem that
  # renamed one must not take every page of every site on the theme down.
  context "with a theme whose icon and share-image assets are gone" do
    before do
      PlaceCal::Extensions.register_theme(:stale_assets) do |theme|
        theme.icons favicon_32: "stale_assets/gone-32.png",
                    icon_192: "stale_assets/gone-192.png"
        theme.og_image "stale_assets/gone-og.png", width: 1200, height: 675
      end
      site_on("stale_assets", "stale")
      allow(Rails.logger).to receive(:warn)
    end

    it "renders the site homepage with core's icons and share card instead" do
      get "http://stale.lvh.me"

      expect(response).to have_http_status(:ok)
      head = head_html
      expect(head).not_to include("gone-32")
      expect(head).not_to include("gone-og")
      expect(head).to match(%r{<link rel="icon" type="image/png" href="[^"]*/assets/favicon-[0-9a-f]+\.png">})
      expect(Rails.logger).to have_received(:warn).with(/gone-32\.png/)
      expect(Rails.logger).to have_received(:warn).with(/gone-og\.png/)
    end

    it "omits the icon from the web manifest rather than raising" do
      get "http://stale.lvh.me/manifest.webmanifest"

      expect(response).to have_http_status(:ok)
      manifest = JSON.parse(response.body)
      expect(manifest["icons"].map { |icon| icon["src"] }.join).not_to include("gone-192")
      expect(manifest["icons"].map { |icon| icon["sizes"] }).to eq(%w[64x64 180x180])
    end
  end

  context "with a theme that pushes head markup through content_for" do
    it "renders the pushed markup inside <head>" do
      PlaceCal::Extensions.register_theme(:head_fallback) do |theme|
        theme.homepage_view "ThemeHeadFallbackHome"
      end
      site_on("head_fallback", "fally")

      get "http://fally.lvh.me"

      expect(response).to have_http_status(:ok)
      expect(head_html).to include('<meta name="theme-head-fallback" content="pushed">')
    end
  end
end
