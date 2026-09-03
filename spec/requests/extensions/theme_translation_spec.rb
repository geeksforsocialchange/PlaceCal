# frozen_string_literal: true

require "rails_helper"

# A theme may override core strings for sites on that theme only (#3368 D19).
RSpec.describe "Theme-scoped translations", type: :request do
  let(:ward) { create(:riverside_ward) }
  let(:london) { create(:partnership, name: "London") }
  let(:manchester) { create(:partnership, name: "Manchester") }

  def tagged_site(slug, theme)
    site = create(:site, slug: slug, theme: theme, url: "https://#{slug}.lvh.me")
    site.neighbourhoods << ward
    site.tags << [london, manchester]
    site
  end

  it "uses the theme's override on a site with that theme" do
    tagged_site("themed", "example_theme")
    get "http://themed.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Anywhere")
    expect(response.body).not_to include(">All<")
  end

  it "leaves other themes on the core string" do
    tagged_site("plain", "pink")
    get "http://plain.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(">All<")
    expect(response.body).not_to include("Anywhere")
  end

  it "falls back to the core string for keys the theme does not override" do
    tagged_site("themed", "example_theme")
    get "http://themed.lvh.me/events"
    expect(response.body).to include(I18n.t("navigation.site.events"))
  end
end
