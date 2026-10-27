# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Select, type: :component do
  let(:options) { [{ id: "arts", name: "Arts" }, { id: "health", name: "Health" }] }

  it "submits through a hidden native select" do
    render_inline(described_class.new(name: "category", options:, selected: "health"))

    expect(page).to have_css("select.sr-only[name='category'] option[value='health'][selected]", visible: :all)
  end

  it "shows the selected label on the trigger" do
    render_inline(described_class.new(name: "category", options:, selected: "health"))

    trigger = page.find("button[data-custom-select-target='trigger']")
    expect(trigger).to have_text("Health")
  end

  it "names the trigger by its label and current value" do
    render_inline(described_class.new(name: "category", label_text: "Category", options:, selected: "health"))

    trigger = page.find("button#category_select")
    expect(trigger["aria-labelledby"]).to eq("category_select_label category_select_value")
    expect(page).to have_css("label#category_select_label[for='category_select']", text: "Category")
    expect(page).to have_css("span#category_select_value", text: "Health")
  end
end
