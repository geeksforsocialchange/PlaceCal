# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Link, type: :component do
  it "renders a link with the given attributes" do
    render_inline(described_class.new(href: "/partners", target: "_blank", data: { turbo_frame: "_top" })) { "Partners" }

    expect(page).to have_link("Partners", href: "/partners")
    expect(page).to have_css("a[target='_blank'][data-turbo-frame='_top']")
  end

  it "rejects an unknown variant" do
    expect { described_class.new(href: "/", variant: :ghost) }.to raise_error(Literal::TypeError)
  end
end
