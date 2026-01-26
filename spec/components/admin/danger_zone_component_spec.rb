# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DangerZoneComponent, type: :component do
  let(:default_params) do
    {
      title: "Delete Partner",
      description: "This will permanently remove the partner.",
      button_text: "Delete",
      button_path: "/admin/partners/1"
    }
  end

  it "renders with title and description" do
    render_inline(described_class.new(**default_params))
    expect(page).to have_css(".card.bg-error\\/5")
    expect(page).to have_text("Delete Partner")
    expect(page).to have_text("This will permanently remove the partner.")
  end

  it "renders warning icon" do
    render_inline(described_class.new(**default_params))
    expect(page).to have_css("svg") # warning icon
  end

  it "renders delete button with correct path" do
    render_inline(described_class.new(**default_params))
    # link_to with data: { turbo_method: :delete } creates a link with data-turbo-method
    expect(page).to have_link("Delete", href: "/admin/partners/1")
    expect(page).to have_css("a[data-turbo-method='delete']")
  end

  it "renders button with error styling" do
    render_inline(described_class.new(**default_params))
    expect(page).to have_css(".btn.btn-error")
  end

  it "adds turbo confirm when confirm is provided" do
    render_inline(described_class.new(**default_params, confirm: "Are you sure?"))
    expect(page).to have_css("[data-turbo-confirm='Are you sure?']")
  end

  it "does not add turbo confirm when not provided" do
    render_inline(described_class.new(**default_params))
    expect(page).not_to have_css("[data-turbo-confirm]")
  end
end
