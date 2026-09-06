# frozen_string_literal: true

require "rails_helper"

# Regression test for issue #2936: a site whose theme names a stylesheet that
# is not in the asset pipeline must not crash with
# Propshaft::MissingAssetError. The page should render with the default styling
# instead. The case that produced the bug was core's per-site `custom` theme,
# which built the path from the site slug; it is now an extension shipping a
# stylesheet that a stale or unbuilt release could still fail to provide.
RSpec.describe "A theme whose stylesheet is missing from the pipeline", :theme_registry, type: :request do
  let(:ward) { create(:riverside_ward) }
  # Lazy, not `let!`: the theme has to be registered before a site can name it.
  let(:site) do
    create(:site,
           slug: "experimentalmusic",
           theme: "unbuilt",
           url: "https://experimentalmusic.lvh.me",
           place_name: "Experimental Music")
  end

  before do
    PlaceCal::Extensions.register_theme(:unbuilt) do |theme|
      theme.stylesheet "unbuilt/theme"
    end
    site.neighbourhoods << ward
  end

  it "does not advertise a stylesheet that is missing from the pipeline" do
    # Guards against accidentally adding the asset in the test environment,
    # which would make the request specs below pass for the wrong reason.
    expect(site.stylesheet_link).to be_nil
  end

  it "renders the site homepage without the missing stylesheet" do
    get "http://experimentalmusic.lvh.me"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("unbuilt/theme")
  end

  it "renders the events index without the missing stylesheet" do
    get "http://experimentalmusic.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("unbuilt/theme")
  end
end
