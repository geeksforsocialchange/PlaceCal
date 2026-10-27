# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Card, type: :component do
  it "renders a div by default" do
    render_inline(described_class.new) { "Body" }

    expect(page).to have_css("div.rounded-card", text: "Body")
  end

  it "renders the given element, passing attributes through" do
    render_inline(described_class.new(tag: :form, action: "/events", method: "get")) { "Filters" }

    expect(page).to have_css("form[action='/events'][method='get']", text: "Filters")
  end

  it "renders a link when given an href" do
    render_inline(described_class.new(href: "/join/councils")) { "Councils" }

    expect(page).to have_link("Councils", href: "/join/councils")
  end

  it "rejects an unknown variant or tag" do
    expect { described_class.new(variant: :ghost) }.to raise_error(Literal::TypeError)
    expect { described_class.new(tag: :script) }.to raise_error(Literal::TypeError)
  end
end
