# frozen_string_literal: true

# Canonical apex URL for the nationwide directory (Site::DIRECTORY_URL).
#
# Anything an environment file set wins (test pins the production URL);
# otherwise derive the apex each environment already declares via
# routes.default_url_options — so development resolves to
# http://lvh.me:3000 and production/staging follow SITE_DOMAIN.
# (.presence because config.x returns a truthy empty OrderedOptions
# for unset keys.)
Rails.application.config.x.directory_url =
  Rails.application.config.x.directory_url.presence ||
  begin
    opts = Rails.application.routes.default_url_options
    url = "#{opts[:protocol] || 'https'}://#{opts[:host]}"
    url += ":#{opts[:port]}" if opts[:port].present?
    url
  end
