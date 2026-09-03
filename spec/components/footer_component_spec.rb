# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Footer, type: :component do
  context "when APP_VERSION is set" do
    before do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "v0.9.1"))
    end

    it "shows the version label linking to the release tag" do
      render_inline(described_class.new(nil))

      link = page.find("a", text: "v0.9.1")
      expect(link[:href])
        .to eq("https://github.com/geeksforsocialchange/PlaceCal/releases/tag/v0.9.1")
    end
  end

  context "when neither APP_VERSION nor GIT_REV is set" do
    before do
      env = ENV.to_hash
      env.delete("APP_VERSION")
      env.delete("GIT_REV")
      stub_const("ENV", env)
    end

    it "falls back to a 'main' build label linking to the repo" do
      render_inline(described_class.new(nil))

      link = page.find("a", text: "main")
      expect(link[:href]).to eq("https://github.com/geeksforsocialchange/PlaceCal")
    end
  end

  describe "site navigation links" do
    let(:site) { create(:site) }
    let(:core_navigation) do
      [
        [I18n.t("navigation.site.home"), "/"],
        [I18n.t("navigation.site.events"), "/events"],
        [I18n.t("navigation.site.partners"), "/partners"]
      ]
    end

    # The layout hands the footer the same derived navigation as the header
    # (SiteNavigation), so the spec constructs one the same way.
    def footer_nav_labels(navigation)
      render_inline(described_class.new(site, navigation: navigation))
      page.all(".footer__nav nav ul li a").map(&:text)
    end

    context "with news, an in-nav page and a join link" do
      let(:navigation) do
        core_navigation + [
          [I18n.t("navigation.site.news"), "/news"],
          ["About", "/about"],
          [I18n.t("navigation.site.join"), "/get-in-touch"]
        ]
      end

      it "renders the derived nav, then the footer's own extras" do
        expect(footer_nav_labels(navigation)).to eq(
          [
            I18n.t("navigation.site.home"),
            I18n.t("navigation.site.events"),
            I18n.t("navigation.site.partners"),
            I18n.t("navigation.site.news"),
            "About",
            I18n.t("navigation.site.join"),
            I18n.t("navigation.site.privacy"),
            I18n.t("navigation.site.terms"),
            I18n.t("navigation.site.log_in")
          ]
        )
      end
    end

    context "with only the core links" do
      it "renders them plus the legal and log-in links" do
        expect(footer_nav_labels(core_navigation)).to eq(
          [
            I18n.t("navigation.site.home"),
            I18n.t("navigation.site.events"),
            I18n.t("navigation.site.partners"),
            I18n.t("navigation.site.privacy"),
            I18n.t("navigation.site.terms"),
            I18n.t("navigation.site.log_in")
          ]
        )
      end

      it "omits Join when the derived navigation has none" do
        expect(footer_nav_labels(core_navigation)).not_to include(I18n.t("navigation.site.join"))
      end
    end

    context "when a region is selected" do
      let(:navigation) do
        [
          [I18n.t("navigation.site.home"), "/?region=hulme"],
          [I18n.t("navigation.site.events"), "/events?region=hulme"],
          [I18n.t("navigation.site.partners"), "/partners?region=hulme"]
        ]
      end

      it "keeps the region param the derived links carry" do
        footer_nav_labels(navigation)

        expect(page).to have_css(
          ".footer__nav nav a[href='/events?region=hulme']",
          text: I18n.t("navigation.site.events")
        )
      end
    end

    context "when the site has its own privacy page in the nav" do
      before { create(:nav_page, site: site, title: "Privacy notice", slug: "privacy") }

      let(:navigation) { core_navigation + [["Privacy notice", "/privacy"]] }

      it "lists it once, under the page's own title, at /privacy" do
        labels = footer_nav_labels(navigation)

        expect(labels.count("Privacy notice")).to eq(1)
        expect(labels).not_to include(I18n.t("navigation.site.privacy"))
        expect(page).to have_css(".footer__nav nav a[href='/privacy']", text: "Privacy notice")
      end
    end
  end

  describe "the directory footer" do
    it "keeps its own fixed link list" do
      render_inline(described_class.new(nil))

      expect(page.all(".footer__nav nav ul li a").map(&:text)).to eq(
        [
          I18n.t("navigation.site.home"),
          I18n.t("navigation.site.events"),
          I18n.t("navigation.site.partners"),
          I18n.t("navigation.site.log_in"),
          I18n.t("navigation.site.privacy"),
          I18n.t("navigation.site.terms")
        ]
      )
    end
  end
end
