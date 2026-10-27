# frozen_string_literal: true

require "rails_helper"

# Public markup builds from the tokens in app/tailwind/public/_theme.css. An arbitrary value or variant
# (`w-[42px]`, `[&>svg]:`, `min-[680px]:`) needs a token, a named utility, or an allowlist entry with a reason.
RSpec.describe "Public Tailwind classes" do
  # Genuine exceptions, keyed by the class without its variant prefixes.
  let(:exceptions) do
    {
      "grid-cols-[1fr_auto]" => "content beside a control that keeps its own width",
      "max-h-[60vh]" => "keeps an open select list inside the viewport",
      "[column-span:all]" => "Tailwind has no column-span utility",
      "border-x-[calc(--spacing(8))]" => "border widths are px; this one follows the spacing scale so it scales with the root size",
      "transition-[display,height,margin-top,padding-block]" => "the mobile menu animates exactly these properties together"
    }
  end

  # Debt to replace with tokens or named utilities. Don't add to this list.
  let(:to_replace) do
    {
      "grid-cols-[64px_1fr]" => "the event row's date tile column: move to the spacing scale",
      "grid-cols-[44px_1fr_auto]" => "the partner row's avatar column: move to the spacing scale",
      "grid-cols-[1.4fr_1fr]" => "join audience split: grid-cols-2 or a named utility",
      "grid-cols-[1.3fr_1fr]" => "join home split: grid-cols-2 or a named utility",
      "grid-cols-[1fr_1.2fr]" => "join home split: grid-cols-2 or a named utility",
      "min-h-[2.4em]" => "pricing card subtitles: line the cards up with subgrid instead"
    }
  end

  let(:allowed) { exceptions.merge(to_replace) }

  let(:files) { Dir[Rails.root.join("app/{components,views}/**/*.rb")].grep_v(%r{/(admin|mailers?)/}) }

  let(:arbitrary) do
    variant = %r{(?:[a-z0-9\-/]+:)*}
    Regexp.union(
      /(?<![\w\-\[])#{variant}!?-?[a-z][a-z0-9-]*-\[[^\]\s]+\]/, # w-[42px], min-[680px]:
      /(?<![\w-])#{variant}\[&[^\]\s]*\]:[a-z0-9:-]+/,           # [&>svg]:hidden
      /(?<![\w-])#{variant}\[[a-z-]+:[^\]\s]+\]/                  # [column-span:all]
    )
  end

  let(:found) do
    files.flat_map do |file|
      File.read(file, encoding: "utf-8").scan(arbitrary).map do |match|
        [Pathname(file).relative_path_from(Rails.root).to_s, match, match.sub(%r{\A(?:[a-z0-9\-/]+:)+}, "")]
      end
    end
  end

  it "uses no arbitrary values or variants outside the allowlist" do
    offences = found.reject { |_, _, key| allowed.key?(key) }.map { |file, match, _| "#{file}: #{match}" }

    expect(offences).to be_empty,
                        "Use a token, a named utility or a plain class instead, or add a genuine exception with a reason:\n#{offences.join("\n")}"
  end

  it "keeps no allowlist entries that nothing uses" do
    expect(allowed.keys - found.map(&:last)).to be_empty
  end
end
