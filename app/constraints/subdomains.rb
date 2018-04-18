module Subdomains
  class Sites
    def self.matches?(request)
      return unless request.subdomain.present?
      if Site.where(slug: request.subdomain).exists?
        true
      else
        raise ActionController::RoutingError.new('Subdomain not Found')
      end
    end
  end
end