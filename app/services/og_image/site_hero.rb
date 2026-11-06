# frozen_string_literal: true

module OgImage
  # For cards drawn over their site's hero image, when it has one.
  module SiteHero
    private

    def hero_path
      return unless site

      path = site.hero_image&.opengraph&.path
      path if path.present? && File.exist?(path)
    end
  end
end
