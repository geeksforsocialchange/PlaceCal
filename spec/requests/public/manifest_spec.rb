# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Web Manifest", type: :request do
  describe "GET /manifest.webmanifest" do
    it "404s on directory" do
      get "http://lvh.me/manifest.webmanifest"
      expect(response).to have_http_status(:not_found)
    end

    describe "on a site subdomain" do
      let(:site) { create(:site, slug: "test-site") }

      before do
        site.update!(is_published: true)
      end

      it "returns 200 with correct content type" do
        get "http://#{site.slug}.lvh.me/manifest.webmanifest"

        expect(response).to be_successful
        expect(response.content_type).to start_with("application/manifest+json")
      end

      it "varies on Host, since the same path serves a different manifest per site" do
        get "http://#{site.slug}.lvh.me/manifest.webmanifest"

        expect(response.headers["Cache-Control"]).to include("public")
        expect(response.headers["Vary"]).to include("Host")
      end

      it "includes the required keys, the site name and the fixed properties" do
        site.update!(name: "Test Site Name")
        get "http://#{site.slug}.lvh.me/manifest.webmanifest"

        manifest = JSON.parse(response.body)
        expect(manifest).to include(
          "name",
          "short_name",
          "start_url",
          "scope",
          "display",
          "background_color",
          "theme_color",
          "icons"
        )
        expect(manifest["name"]).to eq("Test Site Name")
        expect(manifest["start_url"]).to eq("/")
        expect(manifest["scope"]).to eq("/")
        expect(manifest["display"]).to eq("standalone")
      end

      it "truncates short_name to 12 chars at word boundary" do
        site.update!(name: "A Very Long Site Name Here")
        get "http://#{site.slug}.lvh.me/manifest.webmanifest"

        manifest = JSON.parse(response.body)
        expect(manifest["short_name"]).to eq("A Very Long")
        expect(manifest["short_name"].length).to be <= 12
      end

      context "without a logo" do
        it "includes core icons" do
          get "http://#{site.slug}.lvh.me/manifest.webmanifest"

          manifest = JSON.parse(response.body)
          icons = manifest["icons"]
          expect(icons).to be_an(Array)
          expect(icons.length).to eq(2)

          favicon = icons.find { |i| i["sizes"] == "64x64" }
          expect(favicon).to include("type" => "image/png")
          expect(favicon["src"]).to include("favicon")

          apple_icon = icons.find { |i| i["sizes"] == "180x180" }
          expect(apple_icon).to include("type" => "image/png")
          expect(apple_icon["src"]).to include("apple-touch-icon")
        end
      end

      context "with a PNG logo" do
        it "includes the logo and omits core icons" do
          site.update!(logo: fixture_file_upload("test-image.png", "image/png"))
          get "http://#{site.slug}.lvh.me/manifest.webmanifest"

          manifest = JSON.parse(response.body)
          icons = manifest["icons"]
          expect(icons).to be_an(Array)
          expect(icons.length).to eq(1)
          expect(icons[0]["type"]).to eq("image/png")
          expect(icons[0]["sizes"]).to eq("any")
        end
      end
    end
  end

  describe "manifest link in head" do
    let(:site) { create(:site, slug: "test-site") }

    before do
      site.update!(is_published: true)
    end

    it "includes manifest link on site pages" do
      get "http://#{site.slug}.lvh.me"

      expect(response.body).to include('<link rel="manifest" href="/manifest.webmanifest">')
    end

    it "does not include manifest link on directory" do
      get "http://lvh.me"

      expect(response.body).not_to include('rel="manifest"')
    end
  end
end
