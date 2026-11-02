# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Event filter toggle", type: :system do
  let(:ward) { create(:riverside_ward) }
  let(:site) { create(:site, slug: "riverside") }

  before do
    create(:sites_neighbourhood, site:, neighbourhood: ward, relation_type: "Primary")
    partner = create(:partner, address: create(:riverside_address, neighbourhood: ward))
    create(:event, organiser: partner, address: partner.address, dtstart: 2.days.from_now, dtend: 2.days.from_now + 1.hour)
  end

  it "reports whether the filter-and-sort panel is open" do
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}/events"
    toggle = find("button[data-part='toggle-button'][data-variant='sort']")
    panel = "[data-scope='event-filter'][data-part='dropdown']"

    expect(toggle["aria-expanded"]).to eq("false")

    toggle.click
    expect(page).to have_css("#{panel}[data-state='open']")
    expect(toggle["aria-expanded"]).to eq("true")

    toggle.click
    expect(page).to have_css("#{panel}[data-state='closed']", visible: :all)
    expect(toggle["aria-expanded"]).to eq("false")
  end
end
