# frozen_string_literal: true

require "rails_helper"

# The contract themes target (PlaceCal::Theming): every part and variant a component declares renders in its previews.
RSpec.describe "Theming parts", type: :request do
  def preview_for(component)
    Lookbook::Previews.all.find { PlaceCal::Theming.component_for_preview(it) == component.name }
  end

  # Classes the link previews pass in to show call sites, not the link's own.
  PREVIEW_ONLY_TOKENS = { "link" => %w[--font-serif --text-detail --text-sm] }.freeze

  def rendered_previews(preview)
    preview.scenarios.map do |scenario|
      get "#{preview.url_path}/#{scenario.name}/preview"
      Nokogiri::HTML(response.body)
    end
  end

  # Core leaves the organiser prefix blank; a theme fills it.
  before do
    I18n.backend.eager_load!
    I18n.backend.store_translations(:en, events: { card: { organiser_prefix: "by " } })
  end

  after { I18n.reload! }

  PlaceCal::Theming.scopes.each_value.select { it.owner < Components::Base }.each do |scope|
    it "renders every #{scope.css_name} part in its previews" do
      preview = preview_for(scope.owner)
      expect(preview).to be_present, "#{scope.owner} has no Lookbook preview"

      pairs = rendered_previews(preview).flat_map { |html| html.css("[data-part]").map { [it["data-scope"], it["data-part"], it["data-variant"]] } }
      expect(pairs.map(&:first)).not_to include(nil)
      own = pairs.select { it.first == scope.css_name }
      expect(own.map { it[1] }.uniq).to match_array(scope.to_contract[:parts])
      scope.to_contract[:variants].each do |part, variants|
        expect(own.select { it[1] == part }.filter_map(&:last).uniq).to match_array(variants), "#{scope.css_name} #{part} variants"
      end
    end

    it "declares every token the #{scope.css_name} previews read" do
      read = rendered_previews(preview_for(scope.owner)).flat_map { ThemingTokens.read_by(it, scope.css_name) }.uniq

      expect(read - scope.tokens.map(&:to_s) - PREVIEW_ONLY_TOKENS.fetch(scope.css_name, [])).to be_empty
    end
  end

  it "shows a component's scope, parts and tokens in its Lookbook theming panel" do
    get(Lookbook::Previews.all.find { it.lookup_path == "shared/hero" }.url_path.then { "#{it}/record_page" })

    row = Nokogiri::HTML(response.body).css(".theming-panel tr").find { it.at_css("td code")&.text == "back" }
    expect(row.css("td").map { it.text.strip }).to include(a_string_including("The back link"), "<a>", "content", "Record page with back link")
    expect(response.body).to include("--color-primary")
  end

  it "names a preview that fails to render in the theming panel instead of leaving it out" do
    allow(PlaceCal::Theming).to receive(:render_scenario).and_raise(PlaceCal::Theming::UndeclaredPart, "hero has no part :kickr")
    get(Lookbook::Previews.all.find { it.lookup_path == "shared/hero" }.url_path.then { "#{it}/record_page" })

    expect(Nokogiri::HTML(response.body).at_css(".theming-panel").text).to include("Record page with back link: PlaceCal::Theming::UndeclaredPart: hero has no part :kickr")
  end

  it "opens the inspector of a component without hooks" do
    card = Lookbook::Previews.all.find { it.lookup_path == "ui/card" }
    get "#{card.url_path}/#{card.scenarios.first.name}"

    expect(response).to be_successful
    expect(response.body).to include("This component has no theming hooks.")
  end
end
