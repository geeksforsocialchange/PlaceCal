# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public colour themes" do
  let(:root_tokens) do
    Rails.root.join("app/tailwind/public/_theme.css").read[/^:root \{(.*?)^\}/m, 1]
         .scan(/^\s*(--color-[\w-]+):/).flatten
  end

  let(:shades) { root_tokens.grep(/\A--color-(primary|secondary)-/) }

  let(:themes) do
    Rails.root.join("app/tailwind/public/_themes.css").read
         .scan(/html\[data-theme="(\w+)"\]\s*\{([^}]*)\}/)
         .to_h { |name, body| [name, body.scan(/(--[\w-]+):/).flatten] }
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
end
