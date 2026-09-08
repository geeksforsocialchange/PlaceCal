# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Filter, type: :component do
  let(:items) do
    [
      { id: 1, name: "Alpha", count: 2 },
      { id: 2, name: "Beta", count: 3 }
    ]
  end
  let(:base_attrs) do
    {
      name: "category",
      label: "Category",
      items: items,
      controller: "partner-filter-component",
      toggle_action: "toggleCategory",
      submit_action: "submitCategory",
      reset_action: "resetCategory"
    }
  end

  it "renders nothing when there are no items" do
    render_inline(described_class.new(**base_attrs, items: []))

    expect(page).to have_no_css(".filters__toggle")
  end

  describe "idle toggle" do
    it "always shows the facet label in the label span" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("span.filters__toggle-label", text: "Category")
    end

    it "shows the show_all copy in the value span" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css("span.filters__toggle-value", text: I18n.t("filters.show_all"))
    end

    it "keeps the triangle icon" do
      render_inline(described_class.new(**base_attrs))

      expect(page).to have_css('svg[data-icon-name="triangle_down"]')
    end

    it "does not show a reset button" do
      render_inline(described_class.new(**base_attrs))

      expect(page).not_to have_button("Reset")
    end
  end

  describe "active toggle" do
    it "keeps the facet label unchanged in the label span" do
      render_inline(described_class.new(**base_attrs, selected_id: 1))

      expect(page).to have_css("span.filters__toggle-label", text: "Category")
    end

    it "shows the selected item's name in the value span" do
      render_inline(described_class.new(**base_attrs, selected_id: 1))

      expect(page).to have_css("span.filters__toggle-value", text: "Alpha")
    end

    it "shows a reset button" do
      render_inline(described_class.new(**base_attrs, selected_id: 1))

      expect(page).to have_button("Reset")
    end
  end

  it "keeps the same Stimulus target name on the value span" do
    render_inline(described_class.new(**base_attrs))

    expect(page).to have_css("[data-partner-filter-component-target='categoryText'].filters__toggle-value")
  end
end
