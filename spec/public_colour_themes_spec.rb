# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public colour themes" do
  let(:root_tokens) do
    Rails.root.join("app/tailwind/public/_theme.css").read[/^:root \{(.*?)^\}/m, 1]
         .scan(/^\s*(--color-[\w-]+):/).flatten
  end

  let(:shades) { root_tokens.grep(/\A--color-(primary|secondary)-/) }

  let(:theme_blocks) do
    Rails.root.join("app/tailwind/public/_themes.css").read.scan(/html\[data-theme="(\w+)"\]\s*\{([^}]*)\}/).to_h
  end

  let(:themes) { theme_blocks.transform_values { it.scan(/(--[\w-]+):/).flatten } }

  let(:root_hex) do
    Rails.root.join("app/tailwind/public/_theme.css").read[/^:root \{(.*?)^\}/m, 1].scan(/(--color-[\w-]+):\s*(#\h{6});/).to_h
  end

  # Text over a background image, which axe can't measure: the hero's pattern sits on the primary fill.
  let(:text_over_images) { { "hero text on its patterned fill" => %w[--color-foreground-dark --color-primary] } }

  def contrast(*hexes)
    lighter, darker = hexes.map { |hex| luminance(hex) }.sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  def luminance(hex)
    hex.delete("#").scan(/../).map { |c| c.to_i(16) / 255.0 }
       .map { |c| c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4 }
       .zip([0.2126, 0.7152, 0.0722]).sum { |c, weight| c * weight }
  end

  it "has a block for every built-in theme" do
    built_in = PlaceCal::Extensions.themes.select(&:core?).map { it.name.to_s }

    expect(themes.keys).to match_array(built_in)
  end

  it "gives every built-in theme its own value for each primary and secondary shade" do
    expect(shades).not_to be_empty

    themes.each do |name, declared|
      expect(shades - declared).to be_empty, "#{name} doesn't declare #{(shades - declared).join(', ')}"
    end
  end

  it "gives text over a background image AA contrast in every built-in theme" do
    theme_blocks.each do |name, body|
      values = root_hex.merge(body.scan(/(--color-[\w-]+):\s*(#\h{6});/).to_h)

      text_over_images.each do |what, (text, fill)|
        ratio = contrast(values.fetch(text), values.fetch(fill))
        expect(ratio).to be >= 4.5, "#{name}: #{what} is #{ratio.round(2)}:1 (#{values[text]} on #{values[fill]})"
      end
    end
  end
end
