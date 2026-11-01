# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Choice, type: :component do
  it "renders a label containing the checkbox and the text" do
    component = described_class.new(label: "A ring back")
    render_inline(component) { component.input(type: "checkbox", name: "ringback", id: "ringback") }

    expect(page).to have_css("label input[type='checkbox']#ringback", visible: :all)
    expect(page).to have_field("A ring back", type: "checkbox", visible: :all)
  end

  it "keeps extra classes alongside its own" do
    render_inline(described_class.new(label: "More information", box_attributes: { class: "extra", data: { part: "box" } }, class: "outer")) { nil }

    expect(page).to have_css("label.outer.rounded-pill .extra[data-part='box'] svg", visible: :all)
  end
end
