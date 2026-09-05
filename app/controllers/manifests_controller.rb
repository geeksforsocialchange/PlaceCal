# frozen_string_literal: true

class ManifestsController < ApplicationController
  CACHE_TTL = 1.day
  # Home-screen labels are clipped by the launcher well before this, so the
  # manifest picks its own cap rather than shipping the full site name.
  SHORT_NAME_LIMIT = 12

  skip_before_action :set_supporters
  skip_before_action :set_navigation

  before_action :require_site

  def show
    manifest_data = {
      name: current_site.name,
      short_name: short_name(current_site.name),
      start_url: '/',
      scope: '/',
      display: 'standalone',
      background_color: background_color,
      theme_color: theme_color,
      icons: icons
    }
    manifest_data[:description] = description if description.present?

    expires_in CACHE_TTL, public: true
    # The same path serves a different manifest per host, so a shared cache
    # that keys on the path alone would hand one site's manifest to another.
    response.headers['Vary'] = 'Host'
    render json: manifest_data, content_type: 'application/manifest+json'
  end

  private

  def require_site
    head :not_found if current_site.nil?
  end

  def theme_color
    Current.theme.theme_color || '#f19089'
  end

  # A theme may set a distinct splash background (#3368 D1); it falls back to
  # the theme colour, which is what core has always used for both.
  def background_color
    Current.theme.background_color || theme_color
  end

  # The site's tagline, when it has one. Site#og_description returns false
  # rather than nil when unset, which `presence` normalises away.
  def description
    current_site.og_description.presence
  end

  def icons
    theme_icons = Current.theme.icons

    # A theme's own manifest icons win over the site logo (#3368 D1).
    if theme_icons[:icon_192] || theme_icons[:icon_512]
      manifest_icons_for(theme_icons)
    elsif current_site.logo.present? && current_site.logo.file&.content_type == 'image/png'
      [{
        src: current_site.logo.url,
        sizes: 'any',
        type: 'image/png'
      }]
    else
      [
        {
          src: helpers.image_url('favicon.png'),
          sizes: '64x64',
          type: 'image/png'
        },
        {
          src: helpers.image_url('apple-touch-icon.png'),
          sizes: '180x180',
          type: 'image/png'
        }
      ]
    end
  end

  def manifest_icons_for(theme_icons)
    [
      { key: :icon_192, sizes: '192x192' },
      { key: :icon_512, sizes: '512x512' }
    ].filter_map do |icon|
      path = theme_icons[icon[:key]]
      next if path.blank?

      { src: helpers.image_url(path), sizes: icon[:sizes], type: 'image/png' }
    end
  end

  # As many whole words as fit inside SHORT_NAME_LIMIT.
  #
  # @param name [String] the site's full name
  # @return [String] at most SHORT_NAME_LIMIT characters
  def short_name(name)
    words = name.split
    result = +''

    words.each do |word|
      test = result.empty? ? word : "#{result} #{word}"
      break if test.length > SHORT_NAME_LIMIT

      result = test
    end
    return result if result.present?

    # A first word longer than the cap leaves the loop with nothing, so cut it
    # rather than returning the whole untruncated name.
    words.first&.truncate(SHORT_NAME_LIMIT, omission: '') || name
  end
end
