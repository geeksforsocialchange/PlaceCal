# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::Flash, type: :phlex do
  it "renders nothing when flash is empty" do
    render_inline(described_class.new(flash_messages: {}))
    expect(page.text).to be_blank
  end

  it "renders flash messages" do
    flash = { notice: "Saved!", alert: "Warning!" }
    render_inline(described_class.new(flash_messages: flash))
    expect(page).to have_text("Saved!")
    expect(page).to have_text("Warning!")
  end

  it "renders alerts with appropriate types" do
    flash = { success: "Done!" }
    render_inline(described_class.new(flash_messages: flash))
    expect(page).to have_css(".alert.alert-success")
  end
end
