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

# WP 0.3 (#3368, D1/D3): the core layout renders a theme's head component,
# and content_for(:theme_head), inside <head> after the stylesheet chain.
RSpec.describe "Theme head hook", type: :request do
  let(:ward) { create(:riverside_ward) }

  def head_html
    response.body[%r{<head>.*?</head>}m]
  end

  context "with a theme that registers a head component" do
    let!(:site) do
      create(:site, slug: "headly", theme: "example_theme", url: "https://headly.lvh.me").tap do |s|
        s.neighbourhoods << ward
      end
    end

    it "renders the head component inside <head>, after the print stylesheet" do
      get "http://headly.lvh.me"
      expect(response).to have_http_status(:ok)

      head = head_html
      expect(head).to match(%r{<link rel="stylesheet" href="/assets/example_theme/theme-[0-9a-f]+\.css" data-example-theme="head">})
      expect(head.index("data-example-theme")).to be > head.index('media="print"')
    end
  end

  context "with a core theme" do
    let!(:site) do
      create(:site, slug: "pinkly", theme: "pink", url: "https://pinkly.lvh.me").tap do |s|
        s.neighbourhoods << ward
      end
    end

    it "adds no theme head output and keeps the stylesheet chain intact" do
      get "http://pinkly.lvh.me"
      expect(response).to have_http_status(:ok)

      head = head_html
      expect(head).not_to include("data-example-theme")
      expect(head).not_to include("theme-head-fallback")
      chain = head.scan(%r{/assets/(application|public_tailwind|themes/pink|print)-[0-9a-f]+\.css}).flatten
      expect(chain).to eq(%w[application public_tailwind themes/pink print])
    end
  end

  context "with a theme that pushes head markup through content_for", :theme_registry do
    it "renders the pushed markup inside <head>" do
      PlaceCal::Extensions.register_theme(:head_fallback) do |theme|
        theme.homepage_view "ThemeHeadFallbackHome"
      end
      site = create(:site, slug: "fally", theme: "head_fallback", url: "https://fally.lvh.me")
      site.neighbourhoods << ward

      get "http://fally.lvh.me"
      expect(response).to have_http_status(:ok)
      expect(head_html).to include('<meta name="theme-head-fallback" content="pushed">')
    end
  end
end
