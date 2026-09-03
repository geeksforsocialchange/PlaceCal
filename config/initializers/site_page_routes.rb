# frozen_string_literal: true

# Theme content pages (#3368): a theme registers static pages with
# `theme.page`, and they are served at the top level (/about) to match
# PlaceCal's own convention for static pages (D14). This is a catch-all, so it
# must lose to every other route, including routes drawn by extension engines,
# which load after config/routes.rb. `append` blocks run after every route file
# on each draw. Registered here, in an initializer, rather than in
# config/routes.rb: an append block registered inside a routes file is
# registered again on every reload of that file, which then defines the route
# name twice. PlaceCal::Theme checks a registered slug against the reserved
# first path segments derived from the finished route set.
Rails.application.routes.append do
  # HTML only: without the constraint /about.json served the HTML page under a
  # JSON content type. The default fills the format in for the extensionless
  # /about so it still matches.
  get '/:slug', to: 'pages#show', as: :site_page,
                constraints: { slug: /[a-z0-9-]+/, format: 'html' },
                defaults: { format: :html }
end
