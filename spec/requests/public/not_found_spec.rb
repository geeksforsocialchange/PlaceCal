# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unknown paths", type: :request do
  let!(:site) { create(:site, slug: "local-site") }

  def not_found_part(name)
    response.parsed_body.at_css(%([data-scope="not-found"][data-part="#{name}"]))
  end

  it "renders the not-found page in a local site's layout" do
    get "http://#{site.slug}.lvh.me/no-such-page"

    expect(response).to have_http_status(:not_found)
    expect(not_found_part(:title).text).to eq(I18n.t("shared.resource_not_found.title"))
    expect(response.body).to include("<title>#{site.name}")
  end

  it "links on to the site's home, events and partners" do
    get "http://#{site.slug}.lvh.me/some/deeper/path"

    hrefs = not_found_part(:links).css("a").pluck("href")
    expect(hrefs).to eq(["/", "/events", "/partners"])
  end

  it "renders the not-found page in the directory's hero band" do
    get "http://lvh.me/no-such-page"

    expect(response).to have_http_status(:not_found)
    hero_title = response.parsed_body.at_css('[data-scope="page-hero"][data-part="title"]')
    expect(hero_title.text).to eq(I18n.t("shared.resource_not_found.title"))
    expect(not_found_part(:links)).to be_present
  end

  it "leaves paths with a file extension to the static 404" do
    expect { get "http://lvh.me/wp-login.php" }.to raise_error(ActionController::RoutingError)
  end

  it "still serves the routes it falls behind" do
    get "http://#{site.slug}.lvh.me/privacy"
    expect(response).to have_http_status(:ok)

    get "http://lvh.me/up"
    expect(response).to have_http_status(:ok)
  end

  it "leaves the admin and join subdomains redirecting unknown paths" do
    get "http://admin.lvh.me/no-such-page"
    expect(response).to have_http_status(:moved_permanently)

    get "http://join.lvh.me/no-such-page"
    expect(response).to have_http_status(:moved_permanently)
  end
end
