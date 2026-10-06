# frozen_string_literal: true

module Sites
  # The join marketing site: a reserved subdomain with no Site row.
  class JoinHost
    def self.matches?(request)
      request.subdomain == Site::JOIN_SUBDOMAIN
    end
  end

  class Local
    def self.matches?(request)
      return false if request.subdomain == Site::ADMIN_SUBDOMAIN

      site = Site.find_by_request request
      site.present?
    end
  end
end
