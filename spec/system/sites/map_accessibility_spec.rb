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
end
