# frozen_string_literal: true

module SiteJsonLd
  extend ActiveSupport::Concern

  class_methods do
    # Static JSON-LD for the nationwide directory (no Site row backs it).
    # @param base_url [String]
    # @return [Hash]
    def directory_json_ld(base_url)
      {
        '@context' => 'https://schema.org',
        '@type' => 'WebSite',
        'name' => 'PlaceCal',
        'url' => base_url,
        'publisher' => {
          '@type' => 'Organization',
          'name' => 'PlaceCal',
          'url' => self::DIRECTORY_URL,
          'sameAs' => ['https://twitter.com/PlaceCal']
        }
      }
    end
  end

  def to_json_ld
    subsite_json_ld
  end

  private

  def subsite_json_ld
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'WebSite',
      'name' => name,
      'url' => canonical_url
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
