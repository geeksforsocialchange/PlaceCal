# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin layout", :slow, type: :system do
  include_context "admin login"

  let!(:partner) { create(:partner) }

  def active_element
    page.evaluate_script("[document.activeElement.tagName, document.activeElement.id, document.activeElement.textContent.trim()]")
  end

  def page_width
    page.evaluate_script("document.documentElement.scrollWidth")
  end

  it "moves focus to the main content from the skip link" do
    visit admin_url("/partners")

    find("body").send_keys(:tab)
    expect(active_element).to eq(["A", "", I18n.t("navigation.skip_to_content")])
    expect(page).to have_link(I18n.t("navigation.skip_to_content"), visible: :visible)

    page.send_keys(:enter)
    expect(page).to have_current_path(/#main-content\z/, url: true)
    expect(active_element.first(2)).to eq(%w[MAIN main-content])
  end

  # WCAG 1.4.10: the navigation stays reachable at 320px and the page doesn't scroll sideways.
  context "at 320px wide" do
    before { page.current_window.resize_to(320, 640) }

    it "opens and closes the sidebar from the menu button" do
      visit admin_url("/partners")
      toggle = find("button[aria-controls='admin-sidebar']")

      expect(page).to have_no_css("#admin-sidebar a", visible: :visible)

      toggle.click
      expect(toggle["aria-expanded"]).to eq("true")
      expect(page).to have_link(Calendar.model_name.human(count: 2), visible: :visible)
      expect(page_width).to be <= 320

      toggle.click
      expect(toggle["aria-expanded"]).to eq("false")
      expect(page).to have_no_css("#admin-sidebar a", visible: :visible)
    end

    it "does not scroll sideways on a data table page" do
      visit admin_url("/partners")
      await_datatables

      expect(page_width).to be <= 320
    end
  end
end
