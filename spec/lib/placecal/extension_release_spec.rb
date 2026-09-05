# frozen_string_literal: true

require "rails_helper"
# lib/ is not autoloaded; the rake task requires it the same way.
require_relative "../../../lib/placecal/extension_release"

# The Gemfile edit behind rake placecal:extension:bump (#3368 WP 5.2).
# doc/extensions.md calls bumping the tag and relocking the whole deploy step
# for an extension change, so it is worth having one way to do it.
RSpec.describe PlaceCal::ExtensionRelease do
  let(:gemfile) do
    <<~RUBY
      group :extensions do
        gem 'placecal-theme-mossley', github: 'geeksforsocialchange/placecal-theme-mossley', tag: 'v0.1.1'
        gem 'placecal-theme-transdimension', github: 'geeksforsocialchange/placecal-theme-transdimension', tag: 'v0.3.11'
      end
    RUBY
  end

  it "rewrites only the named extension's tag" do
    bumped = described_class.bump(gemfile, "placecal-theme-mossley", "0.1.2")

    expect(bumped).to include("gem 'placecal-theme-mossley', github: 'geeksforsocialchange/placecal-theme-mossley', tag: 'v0.1.2'")
    expect(bumped).to include("tag: 'v0.3.11'")
  end

  it "takes the version with or without its leading v" do
    expect(described_class.bump(gemfile, "placecal-theme-mossley", "v0.1.2"))
      .to eq(described_class.bump(gemfile, "placecal-theme-mossley", "0.1.2"))
  end

  # doc/extensions.md writes the block over several lines, and a real Gemfile
  # may too.
  it "finds the tag on a Gemfile entry that wraps over several lines" do
    wrapped = <<~RUBY
      group :extensions do
        gem 'placecal-theme-mossley',
            github: 'geeksforsocialchange/placecal-theme-mossley',
            tag: 'v0.1.1'
      end
    RUBY

    expect(described_class.bump(wrapped, "placecal-theme-mossley", "0.2.0")).to include("tag: 'v0.2.0'")
  end

  describe "when it cannot do what was asked" do
    it "refuses a version that is not a release number" do
      expect { described_class.bump(gemfile, "placecal-theme-mossley", "0.1") }
        .to raise_error(ArgumentError, /is not a version like 1\.2\.3/)
    end

    it "refuses a gem the Gemfile does not have" do
      expect { described_class.bump(gemfile, "placecal-theme-nowhere", "1.0.0") }
        .to raise_error(ArgumentError, /is not in the Gemfile/)
    end

    # A theme pinned by branch is the thing rule 2 of the Trust section forbids,
    # so this refuses rather than quietly adding a tag beside it.
    it "refuses a gem that is not pinned by tag" do
      loose = "gem 'placecal-theme-mossley', github: 'geeksforsocialchange/placecal-theme-mossley'\n"

      expect { described_class.bump(loose, "placecal-theme-mossley", "1.0.0") }
        .to raise_error(ArgumentError, /is not pinned by tag/)
    end
  end

  it "leaves core's own Gemfile parseable, tag and all" do
    source = Rails.root.join("Gemfile").read
    bumped = described_class.bump(source, "placecal-theme-transdimension", "9.9.9")

    expect(bumped).to include("tag: 'v9.9.9'")
    expect(bumped.lines.length).to eq(source.lines.length)
    expect { RubyVM::InstructionSequence.compile(bumped) }.not_to raise_error
  end
end
