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

  it "renders the cascade controller with the tree serialised as JSON" do
    render_inline(described_class.new(tree: tree))

    root = page.find("[data-controller='neighbourhood-cascade']")
    expect(JSON.parse(root["data-neighbourhood-cascade-tree-value"]))
      .to eq(tree.map { |n| n.transform_keys(&:to_s).merge("children" => n[:children].map { |c| c.transform_keys(&:to_s) }) })
  end

  it "renders a hidden neighbourhood field carrying the selected id" do
    render_inline(described_class.new(tree: tree, selected: "2"))

    field = page.find("input[type='hidden'][name='neighbourhood']", visible: false)
    expect(field[:value]).to eq("2")
    expect(field["data-neighbourhood-cascade-target"]).to eq("field")
  end

  it "renders the selects container the controller fills in" do
    render_inline(described_class.new(tree: tree))

    expect(page).to have_css("[data-neighbourhood-cascade-target='selects']")
  end

  it "labels the control" do
    render_inline(described_class.new(tree: tree))

    expect(page).to have_css("label", text: "Neighbourhood")
  end
end
