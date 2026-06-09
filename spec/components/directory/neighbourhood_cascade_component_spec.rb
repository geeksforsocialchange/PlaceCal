# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Directory::NeighbourhoodCascade, type: :component do
  let(:tree) do
    [
      {
        id: 1, name: "Northvale", unit: "region", count: 3,
        children: [
          { id: 2, name: "Millbrook", unit: "district", count: 3, children: [] }
        ]
      }
    ]
  end

  it "labels the control once" do
    render_inline(described_class.new(tree: tree))

    expect(page).to have_css("label", text: "Neighbourhood", count: 1)
  end

  it "wires up the cascade controller" do
    render_inline(described_class.new(tree: tree))

    expect(page).to have_css("[data-controller='neighbourhood-cascade']")
  end

  it "renders a root dropdown of regions, styled like the other filters" do
    render_inline(described_class.new(tree: tree))

    # Same CustomSelect widget — a hidden select plus a styled trigger button.
    expect(page).to have_css("[data-controller='custom-select'] select[name='neighbourhood']")
    expect(page).to have_text("All neighbourhoods")
    expect(page).to have_text("Northvale (3)")
  end

  it "drills into the selected region with an 'All of' option" do
    render_inline(described_class.new(tree: tree, selected: "1"))

    expect(page).to have_text("All of Northvale")
    expect(page).to have_text("Millbrook (3)")
  end
end
