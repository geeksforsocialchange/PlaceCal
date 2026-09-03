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
      allow(Rails.logger).to receive(:error)
      # The theme must be registered before the site is validated.
      site
    end

    it "renders the site homepage without the missing stylesheet" do
      get "http://brokenly.lvh.me"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("brokenly/theme")
      expect(response.body).to include(site.description)
      expect(Rails.logger).to have_received(:error).with(%r{brokenly/theme\.css})
    end

    it "renders an inner page without the missing head and footer components" do
      get "http://brokenly.lvh.me/news"

      expect(response).to have_http_status(:ok)
      expect(Rails.logger).to have_received(:error).with(/head class Brokenly::Components::Head/)
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
