# frozen_string_literal: true

require "rails_helper"

RSpec.describe SvgIconsHelper, type: :helper do
  it "renders a known icon" do
    expect(helper.icon(:triangle_up)).to include('d="M0,18 l12,-12,12,12 Z"')
  end

  it "renders a custom size" do
    expect(helper.icon(:triangle_up, size: "6")).to include('class="size-6 shrink-0"')
  end

  it "renders a fallback size" do
    expect(helper.icon(:triangle_up)).to include('class="size-5 shrink-0"')
  end

  it "renders a nil size" do
    expect(helper.icon(:triangle_up, size: nil)).to include('class="shrink-0"')
  end

  it "keeps the icon from shrinking in a flex row, once" do
    expect(helper.icon(:triangle_up, css_class: "shrink-0 text-primary")).to include('class="size-5 shrink-0 text-primary"')
  end

  it "renders the icon name" do
    expect(helper.icon(:triangle_up)).to include('data-icon-name="triangle_up"')
  end

  it "renders an error when an invalid icon is passed" do
    expect(helper.icon(:doesntexist)).to include('<span class="text-error">[icon:doesntexist]</span>')
  end
end
