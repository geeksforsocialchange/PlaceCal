# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ListHeading, type: :component do
  it "renders the heading when given text" do
    render_inline(described_class.new("All partners"))

    expect(page).to have_css("h2.list-heading", text: "All partners")
  end

  it "renders nothing for blank text, so core pages stay unchanged" do
    render_inline(described_class.new(""))

    expect(page).not_to have_css("h2")
  end
end
