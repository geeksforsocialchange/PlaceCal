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
