# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Filter results for keyboard and screen reader users", type: :system do
  let(:ward) { create(:riverside_ward) }
  let(:site) { create(:site, slug: "riverside") }
  let(:music) { create(:category, name: "Music") }
  let(:sport) { create(:category, name: "Sport") }

  before do
    create(:sites_neighbourhood, site:, neighbourhood: ward, relation_type: "Primary")
    { "Riverside Choir" => music, "Riverside Runners" => sport, "Riverside Rovers" => sport }.each do |name, category|
      partner = create(:partner, name:, address: create(:riverside_address, neighbourhood: ward))
      partner.categories << category
    end
  end

  def active_element
    page.evaluate_script("[document.activeElement.tagName, document.activeElement.getAttribute('aria-controls')]")
  end

  it "keeps focus on the filter and announces the new count after choosing an option by keyboard" do
    visit "http://riverside.lvh.me:#{Capybara.current_session.server.port}/partners"
    toggle = find("button[aria-controls='category-filter-options']")
    expect(toggle["aria-expanded"]).to eq("false")

    toggle.send_keys(:enter)
    expect(toggle["aria-expanded"]).to eq("true")

    find_field("Sport", visible: :all).send_keys(:space)

    expect(page).to have_css("#partners li", count: 2)
    expect(find("#partner-previews-status", visible: :all)).to have_text(I18n.t("partners.index.results_summary", count: 2), exact: true)
    expect(active_element).to eq(%w[BUTTON category-filter-options])
    expect(find("button[aria-controls='category-filter-options']")["aria-expanded"]).to eq("false")
  end
end
