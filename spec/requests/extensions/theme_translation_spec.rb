# frozen_string_literal: true

require "rails_helper"

# A theme may override core strings for sites on that theme only (#3368 D19).
RSpec.describe "Theme-scoped translations", type: :request do
  let(:ward) { create(:riverside_ward) }
  let(:london) { create(:partnership, name: "London") }
  let(:manchester) { create(:partnership, name: "Manchester") }

  def tagged_site(slug, theme)
    site = create(:site, slug: slug, theme: theme, url: "https://#{slug}.lvh.me")
    site.neighbourhoods << ward
    site.tags << [london, manchester]
    site
  end

  it "uses the theme's override on a site with that theme" do
    tagged_site("themed", "example_theme")
    get "http://themed.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Anywhere")
    expect(response.body).not_to include(">All<")
  end

  it "leaves other themes on the core string" do
    tagged_site("plain", "pink")
    get "http://plain.lvh.me/events"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(">All<")
    expect(response.body).not_to include("Anywhere")
  end

  it "falls back to the core string for keys the theme does not override" do
    tagged_site("themed", "example_theme")
    get "http://themed.lvh.me/events"
    expect(response.body).to include(I18n.t("navigation.site.events"))
  end
end

# The `t` shim itself: it must behave like the `t` it replaces, not just find
# theme overrides (#3368 D19).
RSpec.describe PlaceCal::ThemeTranslation do
  let(:ward) { create(:riverside_ward) }
  let(:themed_site) do
    site = create(:site, slug: "themed", theme: "example_theme", url: "https://themed.lvh.me")
    site.neighbourhoods << ward
    site
  end

  # Stands in for a Phlex component: no `t` further up the ancestor chain.
  let(:component) { Class.new { include PlaceCal::ThemeTranslation }.new }

  # Stands in for a controller or ActionView, where `t` has a super that knows
  # how to expand a lazy ('.foo') key.
  let(:with_super) do
    base = Module.new do
      def t(key, **_options)
        "super:#{key}"
      end
    end
    Class.new do
      include base
      include PlaceCal::ThemeTranslation
    end.new
  end

  before do
    use_current_site(themed_site)
    I18n.backend.store_translations(
      :en,
      spec_shim: { scoped: "Core scoped", symbolic: "Core symbolic" },
      theme_overrides: {
        example_theme: {
          spec_shim: {
            greeting_html: "<b>Hello %{name}</b>", # rubocop:disable Style/FormatStringToken
            scoped: "Override scoped",
            symbolic: "Override symbolic"
          }
        }
      }
    )
  end

  describe "scope:" do
    it "applies the override for the key the scope names" do
      expect(component.t("scoped", scope: "spec_shim")).to eq("Override scoped")
    end

    it "accepts an array scope" do
      expect(component.t("scoped", scope: %i[spec_shim])).to eq("Override scoped")
    end

    it "still finds the core string when the theme overrides nothing there" do
      expect(component.t("symbolic", scope: "spec_shim", default: "Caller default")).to eq("Override symbolic")
      expect(component.t("nothing_here", scope: "spec_shim", default: "Caller default")).to eq("Caller default")
    end
  end

  describe "symbol keys" do
    it "applies the override" do
      expect(component.t(:"spec_shim.symbolic")).to eq("Override symbolic")
    end

    it "hands a lazy symbol key to the including class's own t" do
      expect(with_super.t(:".some_key")).to eq("super:.some_key")
    end
  end

  describe "caller-supplied defaults" do
    it "prefers the unscoped core string over the caller's default" do
      expect(component.t("navigation.site.events", default: "Caller default"))
        .to eq(I18n.t("navigation.site.events"))
    end

    it "falls back to the caller's default when neither the override nor the core key exists" do
      expect(component.t("no.such.key.anywhere", default: "Caller default")).to eq("Caller default")
    end

    it "still prefers the theme's override over both" do
      expect(component.t("region_filter.all", default: "Caller default")).to eq("Anywhere")
    end
  end

  describe "lazy keys" do
    it "hands a leading-dot key to the including class's own t" do
      expect(with_super.t(".some_key")).to eq("super:.some_key")
    end

    it "does not hand an absolute key to it on a themed site" do
      expect(with_super.t("region_filter.all")).to eq("Anywhere")
    end
  end

  describe "_html keys" do
    it "returns an html_safe string and escapes interpolations" do
      result = component.t("spec_shim.greeting_html", name: "<script>")

      expect(result).to be_html_safe
      expect(result).to eq("<b>Hello &lt;script&gt;</b>")
    end

    it "leaves plain keys unmarked" do
      expect(component.t("navigation.site.events")).not_to be_html_safe
    end
  end

  describe "missing translations" do
    it "reports the key the caller wrote, not the theme_overrides path" do
      expect { component.t("definitely.missing.key", raise: true) }
        .to raise_error(I18n::MissingTranslationData) { |error|
          expect(error.message).to include("definitely.missing.key")
          expect(error.message).not_to include("theme_overrides")
        }
    end

    it "reports the same key on a site with no theme override scope" do
      use_current_site(nil)

      expect { component.t("definitely.missing.key", raise: true) }
        .to raise_error(I18n::MissingTranslationData, /definitely\.missing\.key/)
    end

    # Without raise:, I18n returns the message as a string, which is rendered
    # to the reader. It must never name the internal theme_overrides path.
    it "never names the theme_overrides path in the returned message" do
      result = component.t("definitely.missing.key")

      expect(result).to include("definitely.missing.key")
      expect(result).not_to include("theme_overrides")
    end
  end
end
