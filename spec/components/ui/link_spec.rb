# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Link, type: :component do
  it "renders a link with the given attributes" do
    render_inline(described_class.new(href: "/partners", target: "_blank", data: { turbo_frame: "_top" })) { "Partners" }

    expect(page).to have_link("Partners", href: "/partners")
    expect(page).to have_css("a[target='_blank'][data-turbo-frame='_top']")
  end

  it "takes its size and font from props, inheriting both by default" do
    render_inline(described_class.new(href: "/", size: :sm, font: :serif)) { "Support" }
    expect(page).to have_css("a.text-sm.font-serif")

    render_inline(described_class.new(href: "/")) { "Support" }
    expect(page.find("a")[:class]).not_to match(/\b(text-(sm|detail|lg)|font-(serif|mono))\b/)
  end

  it "renders a URL as small mono that can break anywhere" do
    render_inline(described_class.new(href: "/", font: :code)) { "placecal.org/partners/riverside" }

    expect(page).to have_css("a.font-mono.text-sm.break-all")
  end

  it "builds the same classes for links another helper renders" do
    expect(described_class.css(variant: :quiet, size: :detail, font: :serif)).to include("text-detail", "font-serif", "no-underline")
  end

  it "rejects an unknown variant" do
    expect { described_class.new(href: "/", variant: :ghost) }.to raise_error(Literal::TypeError)
  end
end
