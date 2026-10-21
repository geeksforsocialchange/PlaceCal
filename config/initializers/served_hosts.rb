# frozen_string_literal: true

require Rails.root.join('lib/placecal/served_hosts').to_s

# Deployed environments must find their host list at boot; dev and test may run without one.
Rails.application.config.after_initialize do
  PlaceCal::ServedHosts.current.verify! unless Rails.env.local?
end
