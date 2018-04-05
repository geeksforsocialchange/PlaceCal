module Subdomains
  class Truf
    def self.matches?(request)
      if Turf.where(slug: request.subdomain).exists?
        true
      else
        raise ActionController::RoutingError.new('Subdomain not Found')
      end
    end
  end
end