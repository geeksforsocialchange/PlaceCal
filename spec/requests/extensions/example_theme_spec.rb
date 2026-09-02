# frozen_string_literal: true

require "rails_helper"

# WP 0.4 (#3368): proves the extension engine contract with the fixture engine
# under spec/fixtures/extensions/example_theme, with no core config edits.
RSpec.describe "Example theme extension engine", type: :request do
  it "autoloads the engine's own Phlex namespaces" do
    expect(ExampleTheme::Views::Home.superclass).to eq(Views::Base)
    expect(ExampleTheme::Components::Head.superclass).to eq(Components::Base)
    expect(Rails.autoloaders.main.dirs(namespaces: true)).to include(
      ExampleTheme::Engine.root.join("app/views/example_theme").to_s => ExampleTheme::Views,
      ExampleTheme::Engine.root.join("app/components/example_theme").to_s => ExampleTheme::Components
    )
  end

  it "eager loads the engine's directories without naming errors" do
    expect { Rails.autoloaders.main.eager_load_dir(ExampleTheme::Engine.root.join("app/views/example_theme")) }
      .not_to raise_error
    expect { Rails.autoloaders.main.eager_load_dir(ExampleTheme::Engine.root.join("app/components/example_theme")) }
      .not_to raise_error
  end

  it "loads the engine's locale file" do
    expect(I18n.t("example_theme.home.heading")).to eq("Example theme fixture homepage")
  end

  it "serves the engine's committed stylesheet through Propshaft" do
    path = ActionController::Base.helpers.asset_path("example_theme/theme.css")
    expect(path).to match(%r{\A/assets/example_theme/theme-[0-9a-f]+\.css\z})

    get path
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/css")
    expect(response.body).to include("--color-primary: #123456")
  end

  it "renders the engine's homepage view inside the core layout" do
    get "http://lvh.me/example-theme-proof"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<title>Example theme | PlaceCal</title>")
    expect(response.body).to include("Example theme fixture homepage")
    expect(response.body).to include("Rendered without a site")
    # The theme head component is a layout concern (#3368 D1/D3): this page has
    # no site, so no theme definition and no head component output.
    expect(response.body).not_to include("data-example-theme")
    # Core layout chrome is present around the engine view.
    expect(response.body).to include('stylesheet" href="/assets/public_tailwind')
  end

  it "renders the engine's homepage view for a site" do
    site = create(:site, slug: "example", url: "https://example.lvh.me")
    get "http://example.lvh.me/example-theme-proof"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(site.name)
  end
end
