# frozen_string_literal: true

require "rails_helper"

# WP 3.1 (#3368): a theme whose stylesheet was renamed or never built, and
# whose view classes no longer exist, must not take its site down. The site
# renders core's default chrome and the failures are logged.
RSpec.describe "Theme asset and class fallbacks", :theme_registry, type: :request do
  let(:ward) { create(:riverside_ward) }
  let(:site) do
    create(:site, slug: "brokenly", theme: "brokenly", url: "https://brokenly.lvh.me").tap do |s|
      s.neighbourhoods << ward
    end
  end

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
