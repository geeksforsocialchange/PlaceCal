# frozen_string_literal: true

module Sites
  class Local
    def self.matches?(request)
      return false if request.subdomain == Site::ADMIN_SUBDOMAIN

      site = Site.find_by_request request
      site.present?
    end
  end

  # The join.placecal.org marketing site. Checked at request time so the
  # JOIN_SITE_ENABLED flag works without redrawing routes.
  class JoinSite
    def self.matches?(request)
      request.subdomain == Site::JOIN_SUBDOMAIN &&
        Rails.application.config.x.join_site_enabled
    end
  end
end
