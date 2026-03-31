# frozen_string_literal: true

module SiteJsonLd
  extend ActiveSupport::Concern

  def to_json_ld(base_url:)
    if default_site?
      default_site_json_ld(base_url)
    else
      subsite_json_ld(base_url)
    end
  end

  private

  def default_site_json_ld(base_url)
    {
      '@context' => 'https://schema.org',
      '@type' => 'WebSite',
      'name' => 'PlaceCal',
      'url' => base_url,
      'publisher' => {
        '@type' => 'Organization',
        'name' => 'PlaceCal',
        'url' => 'https://placecal.org',
        'sameAs' => ['https://twitter.com/PlaceCal']
      }
    }
  end

  def subsite_json_ld(base_url)
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'WebSite',
      'name' => name,
      'url' => url || base_url
    }

    if logo.present?
      data['publisher'] = {
        '@type' => 'Organization',
        'name' => name,
        'logo' => logo.url
      }
    end

    data
  end
end
