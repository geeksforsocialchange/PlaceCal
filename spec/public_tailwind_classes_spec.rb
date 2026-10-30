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

    expect(offences).to be_empty, "Use a token, a named utility or a plain class instead, or add a genuine exception with a reason:\n#{offences.join("\n")}"
  end

  it "keeps no allowlist entries that nothing uses" do
    expect(allowed.keys - found.map(&:last)).to be_empty
  end

  # Every class in public markup is styled by the built public stylesheet or is a hook listed here.
  describe "classes that compile to nothing" do
    # Classes core's stylesheet leaves alone on purpose. A new hook goes in a group deliberately.
    let(:hooks) do
      {
        "Trans Dimension's theme stylesheet styles these" => %w[
          alt-title-small article article__aside article__author article__back article__content article__image
          article__image-credit article__main article__partners article__published articles articles__article-card
          articles__aside articles__body articles__content articles__image articles__main articles__pagination
          articles__partners articles__published articles__title breadcrumb breadcrumb__element breadcrumb__slot btn btn--alt
          contact_details contact_details__item contact_details__item--social day-strip day-strip__all day-strip__link
          event__more filter-bar filter-bar__category filter-bar__controls filter-bar__label filter-bar__neighbourhood
          filter-bar__reset filter-bar__search filters filters__applied filters__applied-reset filters__dropdown filters__form
          filters__group filters__label filters__link filters__option filters__search filters__toggle
          filters__toggle-button--active filters__toggle-button--date filters__toggle-label filters__toggle-value
          filters__toggles h1 header header__cta header__cta-link header__menu header__partner header__toggle
          header__toggle-label join-actions join-block join-card join-choice join-choice__box join-choices join-control
          join-email-cta join-email-cta__body join-email-cta__heading join-email-link join-grid join-label join-note
          join-submit list-heading map--single meta meta__permalink neighbourhood opening_times opening_times--day opt page
          page-actions page-actions__link paginator__arrow paginator__buttons paginator__context partner-details
          partner-details__aside partner-details__description partner-details__image partner-details__main partners__empty
          place_info__address place_info__directions-list place_info__service_area preview preview__details preview__header
          preview__neighbourhood pullquote region-filter req ruled-heading
        ],
        "Mossley's theme stylesheet styles these" => %w[
          active footer header header__branding header__menu header__partner neighbourhood page paginator__arrow profile
        ],
        "microformats2 h-event properties for feed readers" => %w[h-event p-name dt-start dt-end u-url e-content],
        "paginator_controller.js selects it" => %w[active],
        "specs select these" => %w[nav region-filter--nav filters__group--neighbourhood]
      }
    end

    # Dead classes on main, pinned to their file. Delete each entry once it's fixed; don't add to this list.
    let(:to_fix) do
      {
        "app/components/directory/page_hero.rb" => %w[rounded],
        "app/components/shared/opening_time.rb" => %w[opening_times--time]
      }
    end

    let(:generated) do
      css = Rails.root.join("app/assets/builds/public_tailwind.css").read(encoding: "utf-8").gsub(%r{/\*.*?\*/}m, "")
      css.scan(/([^{}]+)\{/).join(" ").scan(/\.((?:\\.|[a-zA-Z_-])(?:\\.|[\w-])*)/).flatten.to_set { it.gsub(/\\(.)/, '\1') }
    end

    let(:class_tokens) do
      files.flat_map do |file|
        path = Pathname(file).relative_path_from(Rails.root).to_s
        class_strings(Prism.parse_file(file).value).flat_map(&:split).grep_v(/\0/).map { [path, it] }
      end
    end

    # Strings under a class-named key, variable or method, plus any string that already mixes in a styled class.
    def class_strings(node, named: false, strings: [])
      named = class_context?(node, named)
      text = string_text(node)
      strings << text if text && (named || styled_class_string?(text))
      # An interpolated string's literal parts are already in its text; its code can hold class strings of its own.
      children = text ? node.compact_child_nodes.grep_v(Prism::StringNode) : node.compact_child_nodes
      children.each { class_strings(it, named:, strings:) }
      strings
    end

    # Interpolated code becomes a NUL, so a dynamic name like `page--#{slug}` is skipped rather than read as `page--`.
    def string_text(node)
      case node
      when Prism::StringNode then node.unescaped
      when Prism::InterpolatedStringNode then node.parts.map { it.is_a?(Prism::StringNode) ? it.unescaped : "\0" }.join
      end
    end

    # A comparison or a translation inside a class method holds no classes.
    def class_context?(node, named)
      case node
      when Prism::CallNode then named && node.name != :t && !node.name.match?(/\A[!=]=|\?\z/)
      when Prism::AssocNode then named || (node.key.is_a?(Prism::SymbolNode) && node.key.unescaped.match?(/class|css/))
      when Prism::DefNode, Prism::LocalVariableWriteNode, Prism::LocalVariableOrWriteNode, Prism::InstanceVariableWriteNode,
           Prism::InstanceVariableOrWriteNode
        named || node.name.match?(/class|css/)
      else named
      end
    end

    def styled_class_string?(text)
      tokens = text.split.grep_v(/\0/)
      tokens.all?(%r{\A[a-z0-9!*@\[\]()&>:/.%#_,=+~'"-]+\z}) && tokens.any? { generated.include?(it) }
    end

    it "styles every class or lists it as a hook" do
      known = hooks.values.flatten.to_set
      offences = class_tokens.reject { |path, token| generated.include?(token) || known.include?(token) || to_fix.fetch(path, []).include?(token) }
                             .map { |path, token| "#{path}: #{token}" }.uniq

      expect(offences).to be_empty, "These classes compile to nothing. Use a class the public stylesheet generates, or add a hook to a group with its reason:\n#{offences.join("\n")}"
    end

    it "keeps no hooks that nothing uses" do
      expect(hooks.values.flatten.uniq - class_tokens.map(&:last)).to be_empty
    end
  end
end
