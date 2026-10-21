# frozen_string_literal: true

# A site's optional domain, and the URLs that follow from whether this deploy serves it.
module SiteDomain
  extend ActiveSupport::Concern

  # A bare host name: labels of letters, digits and inner hyphens, ending in a TLD.
  DOMAIN_FORMAT = /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{0,61}[a-z0-9]\z/

  included do
    validates :domain, format: { with: DOMAIN_FORMAT }, uniqueness: true, allow_nil: true
  end

  class_methods do
    # @param slug [String]
    # @return [String] e.g. https://<slug>.placecal.org in production
    def subdomain_url_for(slug)
      self::DIRECTORY_URL.sub('://', "://#{slug}.")
    end

    # @param host [String]
    # @return [Site, nil] the site whose domain is host, when this deploy serves it
    def served_at(host)
      host = host.to_s.downcase
      return unless PlaceCal::ServedHosts.current.include?(host)

      find_by(domain: host)
    end

    # Strips any scheme, port, path or trailing dot, so a pasted URL saves as its host.
    #
    # @param value [String, nil]
    # @return [String, nil]
    def normalize_domain(value)
      host = value.to_s.strip.downcase
      host = host.sub(%r{\A[a-z][a-z0-9+.-]*://}, '').split(%r{[/?#]}, 2).first.to_s
      host.sub(/:\d*\z/, '').delete_suffix('.').presence
    end
  end

  # @return [Boolean] whether this deploy's proxy serves the site's domain
  def served_domain?
    domain.present? && PlaceCal::ServedHosts.current.include?(domain)
  end

  # Where PlaceCal serves this site, for sitemaps, robots, permalinks and
  # anything else that names a PlaceCal page.
  #
  # @return [String] no trailing slash
  def canonical_url
    served_domain? ? "https://#{domain}" : subdomain_url
  end

  # Where people should be sent: the site's domain, served or external.
  #
  # @return [String] no trailing slash
  def public_url
    domain.present? ? "https://#{domain}" : canonical_url
  end

  # @return [String] the site's slug subdomain on this environment's apex
  def subdomain_url
    self.class.subdomain_url_for(slug)
  end

  # @return [String] public_url without the scheme, for display
  def display_url
    public_url.sub(%r{\Ahttps?://}, '')
  end
end
