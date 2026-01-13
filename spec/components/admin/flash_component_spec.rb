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
    flash_hash = { "notice" => "Success!", "alert" => "Error!" }
    render_inline(described_class.new(flash: flash_hash))

    expect(page).to have_css(".alert.alert-success")
    expect(page).to have_css(".alert.alert-error")
    expect(page).to have_text("Success!")
    expect(page).to have_text("Error!")
  end
end
