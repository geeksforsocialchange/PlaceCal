# frozen_string_literal: true

# Copies each site's url host into domain, unless it is just the site's own
# <slug> subdomain on a PlaceCal host, which domain leaves blank.
class BackfillSitesDomainFromUrl < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  PLACECAL_HOSTS = %w[placecal.org placecal-staging.org lvh.me].freeze

  def up
    taken = []
    select_rows('SELECT id, slug, url FROM sites WHERE domain IS NULL ORDER BY id').each do |id, slug, url|
      host = host_of(url)
      next if host.nil? || PLACECAL_HOSTS.any? { |placecal| host == "#{slug}.#{placecal}" }

      if taken.include?(host)
        say "Site #{id}: #{host} is already another site's domain, left blank"
        next
      end

      taken << host
      # A few dozen rows, updated one at a time.
      safety_assured { execute "UPDATE sites SET domain = #{quote(host)} WHERE id = #{Integer(id)}" }
    end
  end

  def down
    safety_assured { execute 'UPDATE sites SET domain = NULL' }
  end

  private

  def host_of(url)
    value = url.to_s.strip
    return if value.empty?

    value = "https://#{value}" unless value.match?(%r{\A[a-z][a-z0-9+.-]*://}i)
    URI.parse(value).host&.downcase&.delete_suffix('.').presence
  rescue URI::InvalidURIError
    nil
  end
end
