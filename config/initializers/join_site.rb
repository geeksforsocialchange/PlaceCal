# frozen_string_literal: true

# The join.placecal.org marketing site (#3163) ships dark: routes and chrome
# are constrained to the `join` subdomain AND this flag, so merging the code
# changes nothing on the live site. Enable in production by setting
# JOIN_SITE_ENABLED=true (config/deploy.yml env) once the copy is signed off.
Rails.application.config.x.join_site_enabled =
  ActiveModel::Type::Boolean.new.cast(
    ENV.fetch('JOIN_SITE_ENABLED') { Rails.env.production? ? 'false' : 'true' }
  )
