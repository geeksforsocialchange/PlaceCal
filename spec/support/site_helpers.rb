# frozen_string_literal: true

# Helpers for site-related testing
module SiteHelpers
  # Create the default site required for URL routing
  def create_default_site
    create(:site, slug: 'default-site')
  end

  # Generate a URL for a specific site subdomain
  def site_url(site, path)
    host = Rails.application.routes.default_url_options[:host]
    "http://#{site.slug}.#{host}#{path}"
  end
end

RSpec.configure do |config|
  config.include SiteHelpers
end
