# frozen_string_literal: true

module OgImage
  # A listing or static page: the page's name, under its site's name or PlaceCal's.
  class PageCard < BaseCard
    def initialize(page_title, site: nil)
      super()
      @page_title = page_title
      @site = site
    end

    private

    attr_reader :site

    def hero_path
      return unless site

      path = site.hero_image&.opengraph&.path
      path if path.present? && File.exist?(path)
    end

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
      (site ? site.canonical_url : ::Site::DIRECTORY_URL).sub(%r{\Ahttps?://}, '').chomp('/')
    end

    def compose_watermark(canvas)
      return super unless site

      lockup = powered_by_lockup(logo_height: 34, opacity: 0.82)
      composite(canvas, lockup, WIDTH - 80 - lockup.width, HEIGHT - 60 - lockup.height)
    end
  end
end
