module Subdomains
  class Sites
    def self.matches?(request)
      return unless request.subdomain.present?
      if Site.where(slug: request.subdomain).exists?
        true
      end
    end
  end
end