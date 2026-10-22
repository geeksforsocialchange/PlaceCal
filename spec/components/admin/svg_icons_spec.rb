# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::SvgIcons, type: :phlex do
  let(:component) do
    Class.new(Components::Admin::Base) do
      prop :size, String
      define_method(:view_template) { icon(:partner, size: @size) }
    end
  end

  it "uses the mapped size class when there is one" do
    render_inline(component.new(size: "4"))
    expect(page).to have_css("svg.size-4")
    expect(page.find("svg")[:style]).to be_blank
  end

  it "sizes other icons inline, since Tailwind never generates an interpolated class" do
    render_inline(component.new(size: "3.5"))
    svg = page.find("svg")
    expect(svg[:class].to_s).not_to include("w-3.5")
    expect(svg[:style]).to eq("width: 0.875rem; height: 0.875rem;")
  end
end
