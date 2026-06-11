# frozen_string_literal: true

module OgImage
  # Subdomain site homepage card: the site's own identity with a
  # "Powered by PlaceCal" watermark to keep both identities.
  class SiteCard < BaseCard
    def initialize(site)
      super()
      @site = site
    end

    private

    attr_reader :site

    def label
      t('labels.site')
    end

    def label_colour
      CREAM
    end

    def title
      site.name
    end

    def accent
      ACCENTS[:site]
    end

    def rows
      [
        [:globe, domain],
        [:users, site.tagline]
      ]
    end

    def domain
      URI.parse(site.url).host || site.url
    rescue URI::InvalidURIError
      site.url
    end

    def compose_watermark(canvas)
      logo = svg_asset('logo-header.svg', height: 34)
      powered_by = text(t('powered_by'), size: 19, face: 'Rawline ExtraBold',
                                         colour: ICON_BROWN, letter_spacing: 2)
      group_width = powered_by.width + 12 + logo.width
      x = WIDTH - 80 - group_width
      y = HEIGHT - 60 - logo.height
      canvas = composite(canvas, apply_opacity(powered_by, 0.82), x, y + ((logo.height - powered_by.height) / 2))
      composite(canvas, apply_opacity(logo, 0.82), x + powered_by.width + 12, y)
    end
  end
end
