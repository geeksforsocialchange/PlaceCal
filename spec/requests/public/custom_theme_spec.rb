# frozen_string_literal: true

require "rails_helper"

# Regression test for issue #2936: a site configured with the "custom" theme
# whose per-site stylesheet (themes/custom/<slug>.css) does not exist in the
# asset pipeline must not crash with Propshaft::MissingAssetError. The page
# should render with the default styling instead.
RSpec.describe "Custom theme with missing stylesheet", type: :request do
  let(:ward) { create(:riverside_ward) }
  let!(:site) do
    create(:site,
           slug: "experimentalmusic",
           theme: "custom",
           url: "https://experimentalmusic.lvh.me",
           place_name: "Experimental Music")
  end

  before do
    site.neighbourhoods << ward
  end

  it "does not advertise a custom stylesheet that is missing from the pipeline" do
    # Guards against accidentally adding the asset in the test environment,
    # which would make the request specs below pass for the wrong reason.
    expect(site.stylesheet_link).to be_nil
  end

  it "renders the site homepage without the missing custom stylesheet" do
    get "http://experimentalmusic.lvh.me"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("themes/custom/experimentalmusic")
  end

  it "renders the events index without the missing custom stylesheet" do
    get "http://experimentalmusic.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("themes/custom/experimentalmusic")
  end
end
