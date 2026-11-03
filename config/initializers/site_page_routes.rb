# frozen_string_literal: true

# Theme content pages (#3368): a theme registers static pages with
# `theme.page`, and they are served at the top level (/about) to match
# PlaceCal's own convention for static pages (D14). This is a catch-all, so it
# must lose to every other route, including routes drawn by extension engines,
# which load after config/routes.rb. `append` blocks run after every route file
# on each draw. Registered here, in an initializer, rather than in
# config/routes.rb: an append block registered inside a routes file is
# registered again on every reload of that file, which then defines the route
# name twice.
Rails.application.routes.append do
  # Only a slug some registered theme actually serves is recognised
  # (PlaceCal::Extensions::ThemePage), so other paths reach the not-found
  # route below instead of PagesController. Which theme serves the slug is
  # still the controller's business: the router cannot know the site.
  constraints(PlaceCal::Extensions::ThemePage) do
    # Bare paths only: `format: false` drops the optional .:format segment, so
    # /about.json and /about.html do not route at all rather than serving the
    # HTML page under the wrong content type.
    get '/:slug', to: 'pages#show', as: :site_page,
                  format: false,
                  constraints: { slug: /[a-z0-9-]+/ }
  end

  # Paths with a dot (favicon.ico, wp-login.php) keep Rails' static 404, so file probes stay cheap.
  get '*path', to: 'not_found#show', format: false, constraints: { path: /[^.]+/ }
end
