# frozen_string_literal: true

require "rails_helper"
require_relative "../../../app/components/admin/flash_component"
require_relative "../../../app/components/admin/alert_component"

RSpec.describe Admin::FlashComponent, type: :component do
  it "renders nothing when flash is empty" do
    render_inline(described_class.new(flash: {}))
    expect(page.text).to be_empty
  end

  it "renders alerts for flash messages" do
    flash_hash = { "notice" => "Success message", "alert" => "Alert message" }
    render_inline(described_class.new(flash: flash_hash))

    # notice maps to alert-info, alert maps to alert-warning
    expect(page).to have_css(".alert.alert-info")
    expect(page).to have_css(".alert.alert-warning")
    expect(page).to have_text("Success message")
    expect(page).to have_text("Alert message")
  end
end
