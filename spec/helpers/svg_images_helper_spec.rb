# frozen_string_literal: true

require "rails_helper"

RSpec.describe SvgImagesHelper, type: :helper do
  it "renders an svg with extension" do
    expect(helper.svg_image("home/icons/logo.svg")).to include('<path id="Path_753"')
  end

  it "renders an svg without extension" do
    expect(helper.svg_image("home/icons/logo")).to include('<path id="Path_753"')
  end

  it "renders a custom title" do
    # `inline_svg_tag` gives the `<title/>` element an id
    expect(helper.svg_image("home/icons/logo", alt_text: "A custom title")).to include(%r{<title[^>]*>A custom title</title>})
  end

  it "renders a custom class" do
    expect(helper.svg_image("home/icons/logo", css_class: "custom-class")).to include('class="custom-class"')
  end

  it "renders an error when an invalid path is given" do
    expect(helper.svg_image("aaa/bbb/ccc")).to include("SVG file not found")
  end
end
