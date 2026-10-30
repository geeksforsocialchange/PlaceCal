# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Stripe, type: :component do
  it "is hidden from assistive technology" do
    render_inline(described_class.new)

    expect(page).to have_css("div[aria-hidden='true']", visible: :all)
  end
end
