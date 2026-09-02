# frozen_string_literal: true

require "rails_helper"

# WP 0.2 (#3368, D3): a site whose theme registers a homepage view renders
# that view at the site root, instead of core's default homepage.
RSpec.describe "Extension theme homepage", type: :request do
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  context "with a theme that registers a homepage view" do
    let(:site) do
      create(:site, slug: "exampled", theme: "example_theme", url: "https://exampled.lvh.me")
    end

    it "renders the theme's homepage view" do
      get "http://exampled.lvh.me"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Example theme fixture homepage")
      expect(response.body).to include(site.name)
    end

    it "links the theme's stylesheet" do
      get "http://exampled.lvh.me"
      expect(response.body).to match(%r{/assets/example_theme/theme-[0-9a-f]+\.css})
    end

    it "renders the theme's head component in <head> (#3368 D1/D3)" do
      get "http://exampled.lvh.me"
      head = response.body[%r{<head>.*?</head>}m]
      expect(head).to match(%r{<link rel="stylesheet" href="/assets/example_theme/theme-[0-9a-f]+\.css" data-example-theme="head">})
      expect(head.index("data-example-theme")).to be > head.index("public_tailwind")
    end
  end

  context "with a core theme" do
    let(:site) do
      create(:site, slug: "corely", theme: "pink", url: "https://corely.lvh.me")
    end

    it "renders core's default homepage" do
      get "http://corely.lvh.me"
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Example theme fixture homepage")
      expect(response.body).to include(site.description)
    end
  end
end

RSpec.describe "Region helpers for theme homepage views", type: :request do
  it "exposes region_tags, current_region and region_filter? as helper methods" do
    expect(SitesController.helpers).to respond_to(:region_tags, :current_region, :region_filter?)
  end
end
