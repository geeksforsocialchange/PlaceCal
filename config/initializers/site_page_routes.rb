# frozen_string_literal: true

# Site content pages (#3368, D5): static per-site pages live at the top level
# (/about) to match PlaceCal's own convention for static pages (D14). This is
# a catch-all, so it must lose to every other route, including routes drawn
# by extension engines, which load after config/routes.rb. `append` blocks
# run after every route file on each draw. Registered here, in an initializer,
# rather than in config/routes.rb: an append block registered inside a routes
# file is registered again on every reload of that file, which then defines
# the route name twice. Page validates its slug against the reserved first
# path segments derived from the finished route set.
Rails.application.routes.append do
  get '/:slug', to: 'pages#show', as: :site_page, constraints: { slug: /[a-z0-9-]+/ }
end
