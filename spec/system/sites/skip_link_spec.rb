# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Skip to main content link", type: :system do
  let!(:site) { create(:site, slug: "skiplink") }

  def active_element
    page.evaluate_script("[document.activeElement.tagName, document.activeElement.id, document.activeElement.textContent.trim()]")
  end

  it "is reached by the first Tab and moves focus to the main content" do
    visit "http://skiplink.lvh.me:#{Capybara.current_session.server.port}/"

    find("body").send_keys(:tab)
    expect(active_element).to eq(["A", "", I18n.t("navigation.skip_to_content")])
    expect(page).to have_link(I18n.t("navigation.skip_to_content"), visible: :visible)

    page.send_keys(:enter)
    expect(page).to have_current_path(/#main-content\z/, url: true)
    expect(active_element.first(2)).to eq(%w[MAIN main-content])
  end
end
