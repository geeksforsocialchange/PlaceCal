# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Fieldset, type: :component do
  it "groups its controls under the legend" do
    component = described_class.new(legend: "I'd like")
    render_inline(component) { component.input(type: "checkbox", name: "ringback") }

    expect(page).to have_css("fieldset > legend", text: "I'd like")
    expect(page).to have_css("fieldset input[type='checkbox'][name='ringback']")
  end

  it "passes attributes to the fieldset and legend attributes to the legend" do
    render_inline(described_class.new(legend: "Choices", legend_attributes: { class: "extra", data: { part: "label" } }, class: "outer")) { nil }

    expect(page).to have_css("fieldset.outer > legend.extra[data-part='label']", text: "Choices")
  end
end
