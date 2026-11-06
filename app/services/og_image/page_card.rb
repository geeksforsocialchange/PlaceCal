# frozen_string_literal: true

module OgImage
  # A listing or static page: the page's name, under its site's name or PlaceCal's.
  class PageCard < BaseCard
    include SiteHero

    def initialize(page_title, site: nil)
      super()
      @page_title = page_title
      @site = site
    end

    private

    attr_reader :site

    def hero_lockup
      site ? super : svg_asset('logo-header.svg', height: 32, opacity: 0.85)
    end

    def label
      site ? site.name : 'PlaceCal'
    end

    def title
      @page_title
    end

    def accent
      ACCENTS[:page]
    end

    def rows
      [[:globe, domain]]
    end

    def domain
      bare_domain(site ? site.canonical_url : ::Site::DIRECTORY_URL)
    end

    def compose_watermark(canvas)
      site ? powered_by_watermark(canvas) : super
    end
  end
end
