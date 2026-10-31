# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Pill, type: :component do
  it "renders a link when given an href" do
    render_inline(described_class.new(href: "/events?period=week")) { "This week" }

    expect(page).to have_link("This week", href: "/events?period=week")
  end

  it "renders the selected option as text marked current, not a link" do
    render_inline(described_class.new(selected: true, href: "/events?period=week")) { "This week" }

    expect(page).to have_css("span[aria-current='page']", text: "This week")
    expect(page).not_to have_link
  end

  it "keeps a selected segment a link, marked current" do
    render_inline(described_class.new(variant: :segment, selected: true, href: "/events?region=north")) { "North" }

    expect(page).to have_css("a[href='/events?region=north'][aria-current='page'][data-variant='segment']", text: "North")
  end

  it "marks a selected pill with the given aria-current value" do
    render_inline(described_class.new(variant: :segment, selected: true, current: "date", href: "/events/2022/11/8")) { "Today" }

    expect(page).to have_css("a[aria-current='date']", text: "Today")
  end

  it "renders a span without an href" do
    render_inline(described_class.new(variant: :overlay)) { "Online" }

    expect(page).to have_css("span", text: "Online")
    expect(page).not_to have_css("[aria-current]")
  end

  it "renders a disabled pill as text, not a link" do
    render_inline(described_class.new(variant: :page, href: "/partners?page=0", disabled: true)) { "Previous" }

    expect(page).to have_css("span", text: "Previous")
    expect(page).not_to have_link
  end

  it "rejects an unknown variant" do
    expect { described_class.new(variant: :ghost) }.to raise_error(Literal::TypeError)
  end
end
