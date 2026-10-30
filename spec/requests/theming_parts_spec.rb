# frozen_string_literal: true

require "rails_helper"

# The contract themes target (PlaceCal::Theming): every part a component declares renders in its previews.
RSpec.describe "Theming parts", type: :request do
  def preview_for(component)
    Lookbook::Previews.all.find { "Components::#{it.preview_class_name.delete_suffix('Preview')}" == component.name }
  end

  def rendered_parts(preview)
    preview.scenarios.flat_map do |scenario|
      get "#{preview.url_path}/#{scenario.name}/preview"
      Nokogiri::HTML(response.body).css("[data-part]").map { [it["data-scope"], it["data-part"]] }
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

      pairs = rendered_parts(preview)
      expect(pairs.map(&:first)).not_to include(nil)
      expect(pairs.select { it.first == scope.css_name }.map(&:last).uniq).to match_array(scope.to_contract[:parts])
    end
  end

  it "shows a component's scope, parts and tokens in its Lookbook theming panel" do
    get(Lookbook::Previews.all.find { it.lookup_path == "shared/hero" }.url_path.then { "#{it}/record_page" })

    panel = Nokogiri::HTML(response.body)
    expect(panel.text).to include('[data-scope="hero"][data-part="standfirst-detail"]', "--color-primary")
  end
end
