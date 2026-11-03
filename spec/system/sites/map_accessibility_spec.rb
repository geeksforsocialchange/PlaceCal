# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Map accessibility", type: :system do
  let(:ward) { create(:riverside_ward) }
  let(:site) { create(:site, slug: "riverside") }
  let(:partner) { create(:partner, name: "Riverside Hub", address: create(:riverside_address, neighbourhood: ward)) }

  before { create(:sites_neighbourhood, site:, neighbourhood: ward, relation_type: "Primary") }

  it "names the map and its marker, and hides MapLibre's own canvas region" do
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}/partners/#{partner.to_param}"

    map = find("[role='region'][aria-label='#{I18n.t('components.map.place', name: 'Riverside Hub')}']")
    expect(map).to have_css(".leaflet-marker-icon[role='button'][alt='Riverside Hub']", wait: 15)
    expect(map).to have_css(".leaflet-control-zoom-in[aria-label='#{I18n.t('components.map.zoom_in')}']")
    expect(map).to have_css(".leaflet-gl-layer[aria-hidden='true']", visible: :all, wait: 15)
  end

  it "keeps a map of several places out of the tab order, since the page lists them" do
    partner
    create(:partner, name: "Riverside Library", address: create(:riverside_address, neighbourhood: ward, street_address: "2 River Road", latitude: 53.51, longitude: -2.24))
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}/partners"

    map = find("[role='region'][aria-label='#{I18n.t('components.map.places')}']")
    expect(map).to have_css("img.leaflet-marker-icon[alt='Riverside Hub']", wait: 15)
    expect(map).to have_no_css(".leaflet-marker-icon[tabindex], .leaflet-marker-icon[role='button']")
  end
end
