# frozen_string_literal: true

require "rails_helper"

RSpec.describe SvgIconsHelper, type: :helper do
  it "renders a known icon" do
    expect(helper.icon(:triangle_up)).to include('d="M0,18 l12,-12,12,12 Z"')
  end

  it "renders a custom size" do
    expect(helper.icon(:triangle_up, size: "6")).to include('class="size-6"')
  end

  it "renders a fallback size" do
    expect(helper.icon(:triangle_up)).to include('class="size-5"')
  end

  it "renders a nil size" do
    expect(helper.icon(:triangle_up, size: nil)).to include('class=""')
  end

  it "renders the icon name" do
    expect(helper.icon(:triangle_up)).to include('data-icon-name="triangle_up"')
  end

  it "renders an error when an invalid icon is passed" do
    expect(helper.icon(:doesntexist)).to include('<span class="text-error">[icon:doesntexist]</span>')
  end
end
