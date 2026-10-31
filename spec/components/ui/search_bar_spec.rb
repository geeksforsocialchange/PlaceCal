# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::SearchBar, type: :component do
  it "renders a GET form with a labelled search box and submit button" do
    render_inline(described_class.new(action: "/partners", value: "garden", placeholder: "Search partners", button_label: "Search"))

    expect(page).to have_css("form[action='/partners'][method='get']")
    expect(page).to have_field("q", with: "garden")
    expect(page).to have_css("input[aria-label='Search partners']")
    expect(page).to have_button("Search")
  end

  it "caps its width from a preset and fills its parent by default" do
    render_inline(described_class.new(action: "/", placeholder: "Search", button_label: "Search", width: :md))
    expect(page).to have_css("form.max-w-\\(--width-search\\)")

    render_inline(described_class.new(action: "/", placeholder: "Search", button_label: "Search"))
    expect(page.find("form")[:class]).not_to include("max-w-")
  end
end
