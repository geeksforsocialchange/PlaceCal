# frozen_string_literal: true

module OgImage
  # A partnership is a curated PlaceCal site, shown in the directory.
  class PartnershipCard < BaseCard
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

    # PlaceCal-native card: the bare logo rather than a "Powered by" lockup.
    def hero_lockup
      svg_asset('logo-header.svg', height: 32, opacity: 0.85)
    end

    def label
      t('labels.partnership')
    end

    def title
      site.name
    end

    def accent
      ACCENTS[:partnership]
    end

    def rows
      [
        [:map, site.primary_neighbourhood&.name],
        [:users, partners_text],
        [:calendar, events_text]
      ]
    end

    def partners_text
      return nil if site.partners_count.zero?

      t('partner_organisations', count: site.partners_count)
    end

    def events_text
      count = EventsQuery.new(site: site).scope
                         .where(dtstart: Time.zone.today..30.days.from_now)
                         .count
      return nil if count.zero?

      t('events_this_month', count: count)
    end
  end
end
