# frozen_string_literal: true

module Sites
  class Local
    def self.matches?(request)
      return false if request.subdomain == Site::ADMIN_SUBDOMAIN
      site = Site.find_by_request request
      site&.local_site?
    end
  end
end
