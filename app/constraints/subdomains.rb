# frozen_string_literal: true

module Subdomains
  class Sites
    def self.matches?(request)
      return false unless request.subdomain.present?
      return false if %w[admin www].include? request.subdomain
      Site.where(slug: request.subdomain).exists?
    end
  end
end
