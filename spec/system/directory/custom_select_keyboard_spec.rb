# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Custom select by keyboard", type: :system do
  include_context "normal island data"

  def focused_id
    page.evaluate_script("document.activeElement.id")
  end

  it "reports whether it is open, marks the chosen option and returns focus on Escape" do
    visit public_url("/events")
    trigger = find("#period_select")
    expect(page).to have_css("[data-custom-select-connected='true']")
    expect(trigger["aria-expanded"]).to eq("false")
    expect(page).to have_css("##{trigger['aria-controls']} button[aria-current='true']", count: 1, visible: :all)

    trigger.send_keys(:enter)
    expect(trigger["aria-expanded"]).to eq("true")

    page.send_keys(:tab)
    expect(page.evaluate_script("document.activeElement.closest('##{trigger['aria-controls']}') !== null")).to be(true)

    page.send_keys(:escape)
    expect(trigger["aria-expanded"]).to eq("false")
    expect(focused_id).to eq("period_select")
  end
end
