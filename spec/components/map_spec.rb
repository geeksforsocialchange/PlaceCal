# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Map, type: :phlex do
  let(:points) { [{ lat: 53.4808, lon: -2.2426, name: "Test Place", id: 1 }] }
  let(:site_slug) { "default" }

  it "renders nothing when points are nil" do
    render_inline(described_class.new(points: nil, site: site_slug))
    expect(page.text).to be_empty
  end

  it "renders nothing when points are empty" do
    render_inline(described_class.new(points: [], site: site_slug))
    expect(page.text).to be_empty
  end

  it "renders a div with leaflet controller when points present" do
    render_inline(described_class.new(points: points, site: site_slug))
    expect(page).to have_css('[data-controller="leaflet"]')
  end

  it "sets the leaflet args data attribute" do
    render_inline(described_class.new(points: points, site: site_slug))
    expect(page).to have_css("[data-leaflet-args-value]")
  end

  it "passes style to the map helper" do
    render_inline(described_class.new(points: points, site: site_slug, style: :multi))
    args = page.find("[data-leaflet-args-value]")["data-leaflet-args-value"]
    expect(args).to include("map--multiple")
  end

  it "passes compact to the map helper" do
    render_inline(described_class.new(points: points, site: site_slug, compact: true))
    args = page.find("[data-leaflet-args-value]")["data-leaflet-args-value"]
    expect(args).to include("map--compact")
  end
end
