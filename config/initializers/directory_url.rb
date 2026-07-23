# frozen_string_literal: true

# Canonical apex URL for the nationwide directory (Site::DIRECTORY_URL).
#
# Precedence: ENV['DIRECTORY_URL'], then anything an environment file set
# (test pins the production URL), then the apex each environment already
# declares via routes.default_url_options — so development resolves to
# http://lvh.me:3000 and production/staging follow SITE_DOMAIN.
Rails.application.config.x.directory_url =
  ENV['DIRECTORY_URL'].presence ||
  Rails.application.config.x.directory_url.presence ||
  begin
    opts = Rails.application.routes.default_url_options
    url = "#{opts[:protocol] || 'https'}://#{opts[:host]}"
    url += ":#{opts[:port]}" if opts[:port].present?
    url
  end
