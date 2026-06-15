# frozen_string_literal: true

module OgImage
  # Subdomain site homepage card: the site's own identity with a
  # "Powered by PlaceCal" lockup to keep both identities. When the site
  # has a hero image it fills the background with the identity in a cream
  # panel on top (see BaseCard#render_with_hero); otherwise the type-only
  # layout is used.
  class SiteCard < BaseCard
    def initialize(site)
      super()
      @site = site
    end

    private

    attr_reader :site

    def hero_path
      path = site.hero_image&.opengraph&.path
      path if path.present? && File.exist?(path)
    end

    def label
      t('labels.community_site')
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
        [:map, site.primary_neighbourhood&.name],
        [:users, site.tagline]
      ]
    end

    def domain
      URI.parse(site.url).host || site.url
    rescue URI::InvalidURIError
      site.url
    end

    def compose_watermark(canvas)
      lockup = powered_by_lockup(logo_height: 34, opacity: 0.82)
      composite(canvas, lockup, WIDTH - 80 - lockup.width, HEIGHT - 60 - lockup.height)
    end
  end
end
