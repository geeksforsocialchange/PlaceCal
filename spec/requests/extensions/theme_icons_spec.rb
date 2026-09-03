# frozen_string_literal: true

require "rails_helper"

# WP 3.9 (#3368): a theme supplies its own favicons, touch icon, Safari mask
# icon, manifest icons and colours, and a static Open Graph share image.
RSpec.describe "Theme icons", type: :request do
  let(:ward) { create(:riverside_ward) }

  def head_html
    response.body[%r{<head>.*?</head>}m]
  end

  context "with a theme that registers icons" do
    let!(:site) do
      create(:site, slug: "iconly", theme: "example_theme", url: "https://iconly.lvh.me").tap do |s|
        s.neighbourhoods << ward
      end
    end

    it "links the theme's icons in place of core's" do
      get "http://iconly.lvh.me"
      expect(response).to have_http_status(:ok)

      head = head_html
      expect(head).to match(%r{<link rel="icon" type="image/png" sizes="32x32" href="http://iconly\.lvh\.me/assets/example_theme/icons/favicon-32x32-[0-9a-f]+\.png">})
      expect(head).to match(%r{<link rel="icon" type="image/png" sizes="16x16" href="[^"]*favicon-16x16-[0-9a-f]+\.png">})
      expect(head).to match(/<link rel="apple-touch-icon" sizes="180x180" href="[^"]*apple-touch-icon-[0-9a-f]+\.png">/)
      expect(head).to match(/<link rel="mask-icon" href="[^"]*mask-icon-[0-9a-f]+\.svg" color="#FF7AA7">/)

      expect(head).not_to match(%r{href="[^"]*/assets/favicon-[0-9a-f]+\.png"})
      expect(head).not_to include('rel="apple-touch-icon" href=')
    end

    it "emits the theme-color meta" do
      get "http://iconly.lvh.me"

      expect(head_html).to include('<meta name="theme-color" content="#ff7aa7">')
    end

    it "uses the theme's static Open Graph image" do
      get "http://iconly.lvh.me"

      head = head_html
      expect(head).to match(%r{<meta property="og:image" content="[^"]*/assets/example_theme/icons/og-[0-9a-f]+\.png">})
      expect(head).to include('<meta property="og:image:width" content="1200">')
      expect(head).to include('<meta property="og:image:height" content="675">')
      expect(head).to match(/<meta property="og:image:alt" content="#{Regexp.escape(site.name)}[^"]*">/)
    end

    it "serves every icon asset it links" do
      get "http://iconly.lvh.me"

      hrefs = head_html.scan(%r{href="(http://iconly\.lvh\.me/assets/example_theme/icons/[^"]+)"}).flatten
      expect(hrefs.length).to eq(4)

      hrefs.each do |href|
        get href
        expect(response).to have_http_status(:ok), "expected #{href} to resolve"
      end
    end

    describe "the web manifest" do
      subject(:manifest) do
        get "http://iconly.lvh.me/manifest.webmanifest"
        JSON.parse(response.body)
      end

      it "uses the theme's icons" do
        icons = manifest["icons"]
        expect(icons.length).to eq(2)
        expect(icons.map { |i| i["sizes"] }).to eq(%w[192x192 512x512])
        expect(icons[0]["src"]).to match(%r{/assets/example_theme/icons/icon-192-[0-9a-f]+\.png})
        expect(icons[1]["src"]).to match(%r{/assets/example_theme/icons/icon-512-[0-9a-f]+\.png})
        expect(icons.map { |i| i["type"] }).to all(eq("image/png"))
      end

      it "uses the theme's colours" do
        expect(manifest["background_color"]).to eq("#040f39")
        expect(manifest["theme_color"]).to eq("#ff7aa7")
      end

      it "includes the site description" do
        expect(manifest["description"]).to eq(site.tagline)
      end
    end
  end

  context "with a core theme" do
    let!(:site) do
      create(:site, slug: "plainly", theme: "pink", url: "https://plainly.lvh.me").tap do |s|
        s.neighbourhoods << ward
      end
    end

    it "keeps core's favicon and touch icon" do
      get "http://plainly.lvh.me"
      expect(response).to have_http_status(:ok)

      head = head_html
      expect(head).to match(%r{<link rel="icon" type="image/png" href="[^"]*/assets/favicon-[0-9a-f]+\.png">})
      expect(head).to match(%r{<link rel="apple-touch-icon" href="[^"]*/assets/apple-touch-icon-[0-9a-f]+\.png">})
      expect(head).not_to include("mask-icon")
      expect(head).not_to include("example_theme/icons")
    end

    it "keeps the generated share card" do
      get "http://plainly.lvh.me"

      head = head_html
      expect(head).to include('<meta property="og:image:width" content="1200">')
      expect(head).to include('<meta property="og:image:height" content="630">')
      expect(head).not_to include("icons/og-")
    end
  end

  context "with a theme that sets no colours or icons", :theme_registry do
    let!(:site) do
      PlaceCal::Extensions.register_theme(:bare_theme)
      create(:site, slug: "barely", theme: "bare_theme", url: "https://barely.lvh.me").tap do |s|
        s.neighbourhoods << ward
      end
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
end
