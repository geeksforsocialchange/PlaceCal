# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Shared::Flash, type: :phlex do
  it "renders nothing when there are no messages" do
    render_inline(described_class.new(flash_messages: {}))
    expect(page.text).to be_blank
  end

  it "marks alerts and notices as different states" do
    render_inline(described_class.new(flash_messages: { notice: "Saved", alert: "Broken" }))
    expect(page).to have_css("[role='alert'].bg-primary", text: "Saved")
    expect(page).to have_css("[role='alert'].bg-secondary", text: "Broken")
  end
end
