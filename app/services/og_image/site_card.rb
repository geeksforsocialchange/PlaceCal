# frozen_string_literal: true

module OgImage
  # Subdomain site homepage card: the site's own identity with a
  # "Powered by PlaceCal" lockup to keep both identities. When the site
  # has a hero image it fills the background with the identity in a cream
  # panel on top (see BaseCard#render_with_hero); otherwise the type-only
  # layout is used.
  class SiteCard < BaseCard
    include SiteHero

    def initialize(site)
      super()
      @site = site
    end

    private

    attr_reader :site

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
      bare_domain(site.canonical_url)
    end

    def compose_watermark(canvas)
      powered_by_watermark(canvas)
    end
  end
end
