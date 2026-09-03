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

    def footer_nav_labels
      render_inline(described_class.new(site))
      page.all(".footer__nav nav ul li a").map(&:text)
    end

    context "with news, an in-nav page and a contact email" do
      before do
        create(:nav_page, site: site, title: "About", slug: "about")
        allow(site).to receive(:news_article_count).and_return(3)
        site.contact_email = "hello@example.com"
      end

      it "renders the derived nav in order" do
        expect(footer_nav_labels).to eq(
          [
            I18n.t("navigation.site.home"),
            I18n.t("navigation.site.events"),
            I18n.t("navigation.site.partners"),
            I18n.t("navigation.site.news"),
            "About",
            I18n.t("navigation.site.privacy"),
            I18n.t("navigation.site.terms"),
            I18n.t("navigation.site.join"),
            I18n.t("navigation.site.log_in")
          ]
        )
      end
    end

    context "with no news, no pages and no contact email" do
      it "renders only the core links" do
        expect(footer_nav_labels).to eq(
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
    end

    context "when the site has its own privacy page in the nav" do
      before { create(:nav_page, site: site, title: "Privacy notice", slug: "privacy") }

      it "does not list it twice: /privacy already serves it" do
        expect(footer_nav_labels).not_to include("Privacy notice")
        expect(footer_nav_labels.count(I18n.t("navigation.site.privacy"))).to eq(1)
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
