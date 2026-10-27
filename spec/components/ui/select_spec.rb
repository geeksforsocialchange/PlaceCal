# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Select, type: :component do
  let(:options) { [{ id: "arts", name: "Arts" }, { id: "health", name: "Health" }] }

  it "submits through a hidden native select" do
    render_inline(described_class.new(name: "category", options:, selected: "health"))

    expect(page).to have_css("select.sr-only[name='category'] option[value='health'][selected]", visible: :all)
  end

  it "shows the selected label on a trigger styled like UI::Input" do
    render_inline(described_class.new(name: "category", options:, selected: "health"))

    trigger = page.find("button[data-custom-select-target='trigger']")
    expect(trigger).to have_text("Health")
    expect(trigger[:class]).to include(Components::UI::Input::BOX)
  end
end
