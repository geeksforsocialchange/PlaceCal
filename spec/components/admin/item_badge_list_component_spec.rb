# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ItemBadgeListComponent, type: :component do
  # Create a simple struct to mock items
  Item = Struct.new(:id, :name, keyword_init: true)
  ItemWithContextualName = Struct.new(:id, :name, :contextual_name, keyword_init: true)

  let(:items) do
    [
      Item.new(id: 1, name: "First Item"),
      Item.new(id: 2, name: "Second Item")
    ]
  end

  before do
    # Stub route helper
    allow_any_instance_of(described_class).to receive(:item_path) do |_, item|
      "/admin/items/#{item.id}/edit"
    end
  end

  it "renders items as badge links" do
    render_inline(described_class.new(
                    items: items,
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path
                  ))

    expect(page).to have_css("a", count: 2)
    expect(page).to have_text("First Item")
    expect(page).to have_text("Second Item")
  end

  it "renders links with correct href" do
    render_inline(described_class.new(
                    items: items,
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path
                  ))

    expect(page).to have_link("First Item", href: "/admin/items/1/edit")
    expect(page).to have_link("Second Item", href: "/admin/items/2/edit")
  end

  it "displays icon for each item" do
    render_inline(described_class.new(
                    items: items,
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path
                  ))

    # Each link should contain an SVG icon
    expect(page).to have_css("a svg", count: 2)
  end

  it "uses contextual_name when available" do
    items_with_contextual = [
      ItemWithContextualName.new(id: 1, name: "Short", contextual_name: "Full Contextual Name")
    ]

    render_inline(described_class.new(
                    items: items_with_contextual,
                    icon_name: :map_pin,
                    icon_color: "bg-sky-100 text-sky-600",
                    link_path: :admin_neighbourhood_path
                  ))

    expect(page).to have_text("Full Contextual Name")
    expect(page).not_to have_text("Short")
  end

  it "shows empty state when no items" do
    render_inline(described_class.new(
                    items: [],
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path,
                    empty_text: "No partners assigned"
                  ))

    expect(page).not_to have_css("a")
    expect(page).to have_text("No partners assigned")
  end

  it "shows default empty text when not provided" do
    render_inline(described_class.new(
                    items: [],
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path
                  ))

    expect(page).to have_css(".text-base-content\\/50")
  end

  it "applies correct background color class" do
    render_inline(described_class.new(
                    items: items,
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path
                  ))

    expect(page).to have_css("a.bg-emerald-50")
  end

  it "applies correct text color class" do
    render_inline(described_class.new(
                    items: items,
                    icon_name: :partner,
                    icon_color: "bg-emerald-100 text-emerald-600",
                    link_path: :edit_admin_partner_path
                  ))

    expect(page).to have_css("a.text-emerald-700")
  end

  it "renders empty state icon in center" do
    render_inline(described_class.new(
                    items: [],
                    icon_name: :partnership,
                    icon_color: "bg-amber-100 text-amber-600",
                    link_path: :edit_admin_tag_path
                  ))

    expect(page).to have_css(".text-center svg")
  end
end
