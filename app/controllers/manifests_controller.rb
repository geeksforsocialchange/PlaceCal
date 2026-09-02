# frozen_string_literal: true

class ManifestsController < ApplicationController
  CACHE_TTL = 1.day

  skip_before_action :set_supporters
  skip_before_action :set_navigation

  before_action :set_site
  before_action :require_site

  def show
    manifest_data = {
      name: site.name,
      short_name: short_name(site.name),
      start_url: '/',
      scope: '/',
      display: 'standalone',
      background_color: theme_color,
      theme_color: theme_color,
      icons: icons
    }

    expires_in CACHE_TTL, public: true
    render json: manifest_data, content_type: 'application/manifest+json'
  end

  private

  attr_reader :site

  def require_site
    head :not_found if site.nil?
  end

  def theme_color
    site&.theme_definition&.theme_color || '#f19089'
  end

  def icons
    if site.logo.present? && site.logo.file&.content_type == 'image/png'
      [{
        src: site.logo.url,
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

  def short_name(name)
    words = name.split
    result = +''

    words.each do |word|
      test = result.empty? ? word : "#{result} #{word}"
      break if test.length > 12

      result = test
    end

    result.presence || name
  end
end
