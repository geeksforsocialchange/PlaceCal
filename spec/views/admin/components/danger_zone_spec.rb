# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Admin::Components::DangerZone, type: :phlex do
  let(:default_attrs) do
    {
      title: "Delete Partner",
      description: "This action cannot be undone.",
      button_text: "Delete",
      button_path: "/admin/partners/1"
    }
  end

  it "renders title and description" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_text("Delete Partner")
    expect(page).to have_text("This action cannot be undone.")
  end

  it "renders warning icon" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_css("svg")
  end

  it "renders delete button with correct path" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_link("Delete", href: "/admin/partners/1")
  end

  it "uses error styling" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_css(".text-error")
    expect(page).to have_css(".btn.btn-error")
  end

  it "renders confirm dialog when provided" do
    render_inline(described_class.new(**default_attrs, confirm: "Are you sure?"))
    expect(page).to have_css("[data-turbo-confirm='Are you sure?']")
  end
end
