# frozen_string_literal: true

# config/routes.rb
Rails.application.routes.draw do
  # ============================================================
  # Infrastructure
  # ============================================================
  get 'up', to: proc { [200, {}, ['OK']] }

  devise_for :users,
             controllers: {
               invitations: 'users/invitations',
               sessions: 'users/sessions',
               passwords: 'users/passwords'
             }

  # ============================================================
  # Admin (admin.lvh.me / admin.placecal.org)
  # ============================================================
  scope module: :admin, as: :admin, constraints: { subdomain: 'admin' } do
    resources :articles, except: [:show]
    resources :calendars do
      collection do
        post :test_source
      end
      member do
        post :import
      end
    end
    resources :collections
    resources :neighbourhoods do
      collection do
        get :children
        get :hierarchy
      end
    end
    resources :partners do
      collection do
        get :lookup_name
      end
      member do
        delete :clear_address
      end
    end
    resources :partnerships
    resources :sites
    resources :supporters
    resources :tags
    resources :users, except: [:show] do
      collection do
        get :lookup_email
      end
      member do
        patch :update_profile
      end
    end

    get 'icons', to: 'pages#icons', as: :icons
    get 'jobs', to: 'jobs#index', as: :jobs
    get 'profile', to: 'users#profile', as: :profile

    root 'pages#home'
  end

  # robots.txt is intentionally served on every host (the admin subdomain
  # returns a disallow-all), so it must be matched before the admin redirect
  # below. Other technical routes (sitemaps, graphql) are fine to redirect.
  get '/robots.txt', to: 'pages#robots'

  # The admin subdomain has no Site row and is not the nationwide directory.
  # Public routes carry no subdomain constraint, so any path that isn't an
  # admin route (e.g. /events, /news, /places) would otherwise fall through to
  # the public controllers, which assume a current_site and raise on the
  # site-less admin host (#3267). Bounce those requests to the apex instead.
  match '*path', via: :all,
                 constraints: { subdomain: Site::ADMIN_SUBDOMAIN },
                 to: redirect { |_params, request|
                   host = request.host.delete_prefix('admin.')
                   port = request.optional_port ? ":#{request.optional_port}" : ''
                   "#{request.protocol}#{host}#{port}#{request.fullpath}"
                 }

  # ============================================================
  # Join marketing site (join.placecal.org, #3163)
  # ============================================================
  # Replaces the old apex audience pages, whose URLs redirect here.
  constraints(subdomain: Site::JOIN_SUBDOMAIN) do
    scope as: :join, module: :join, controller: :pages do
      get '/', action: :home, as: :root
      get 'who-its-for', action: :audiences, as: :audiences
      get 'who-its-for/:slug', action: :audience, as: :audience
      get 'features', action: :features, as: :features
      get 'our-story', action: :our_story, as: :our_story
      get 'pricing', action: :pricing, as: :pricing
      get 'book-a-demo', action: :demo, as: :demo
      post 'book-a-demo', action: :demo_create
    end
  end

  # Anything else on the join subdomain bounces to the apex, mirroring the
  # admin catch-all above.
  match '*path', via: :all,
                 constraints: { subdomain: Site::JOIN_SUBDOMAIN },
                 to: redirect { |_params, request|
                   host = request.host.delete_prefix('join.')
                   port = request.optional_port ? ":#{request.optional_port}" : ''
                   "#{request.protocol}#{host}#{port}#{request.fullpath}"
                 }

  # ============================================================
  # Public site
  # ============================================================

  # Local site homepages must match before the default root
  constraints(Sites::Local) do
    get '/', to: 'sites#index'
  end

  root 'pages#home'

  ymd = { year: /\d{4}/,
          month: /\d{1,2}/,
          day: /\d{1,2}/ }

  # Open Graph share card images (#2077)
  get '/opengraph.png', to: 'og_images#default', as: :og_image
  get '/events/:id/opengraph.png', to: 'og_images#event', as: :event_og_image
  get '/partners/:id/opengraph.png', to: 'og_images#partner', as: :partner_og_image
  get '/partnerships/:id/opengraph.png', to: 'og_images#partnership', as: :partnership_og_image

  # Events
  resources :events, only: %i[index show]
  get '/events/:year/:month/:day', to: 'events#index', constraints: ymd, as: :events_by_date

  # Partners
  resources :partners, only: %i[index show]
  resources :partnerships, only: %i[index show]
  get '/partners/:id/events', to: 'partners#show'
  get '/partners/:id/events/:year/:month/:day', to: 'partners#show', constraints: ymd
  get '/places', to: 'partners#index'
  get '/partners/:id/embed', to: 'places#embed'

  # News
  resources :news, only: %i[index show]

  # Static pages (also listed in SitemapsController#build_pages — update both)
  get 'get-in-touch', to: 'joins#new'
  post 'get-in-touch', to: 'joins#create'
  get 'privacy', to: 'pages#privacy'
  get 'terms-of-use', to: 'pages#terms_of_use'

  # ============================================================
  # Legacy & deprecated
  # ============================================================

  # Legacy routes from when some Partners were Places
  get '/places/:id', to: 'partners#show'
  get '/places/:id/events', to: 'partners#show'
  get '/places/:id/events/:year/:month/:day', to: 'partners#show', constraints: ymd
  get '/places/:id/embed', to: 'places#embed'

  get 'our-story', to: 'pages#our_story'

  # The legacy informational pages are deleted (#3163). Their URLs redirect:
  # find-placecal's job is done by the directory homepage, and the audience
  # pitches live on the join site.
  get 'find-placecal', to: redirect('/')
  %w[community-groups metropolitan-areas vcses housing-providers
     social-prescribers culture-tourism].each do |audience_slug|
    get audience_slug, to: redirect { |_params, request|
      # These routes are reachable on every host, including partner sites'
      # custom domains, where join.<request.domain> wouldn't exist — always
      # target the canonical join host in production.
      if Rails.env.production?
        "https://join.placecal.org/who-its-for/#{audience_slug}"
      else
        port = request.optional_port ? ":#{request.optional_port}" : ''
        "#{request.protocol}join.#{request.domain}#{port}/who-its-for/#{audience_slug}"
      end
    }
  end

  # Deprecated: collections
  resources :collections, only: %i[show]
  get 'winter2017', to: 'collections#show', id: 1
  get 'winter2018', to: 'collections#show', id: 2

  # ============================================================
  # Technical (SEO, API, dev tools)
  # ============================================================
  get '/sitemap.xml', to: 'sitemaps#index', defaults: { format: :xml }
  get '/sitemap/partners.xml', to: 'sitemaps#partners', defaults: { format: :xml }
  get '/sitemap/events.xml', to: 'sitemaps#events', defaults: { format: :xml }
  get '/sitemap/partnerships.xml', to: 'sitemaps#partnerships', defaults: { format: :xml }
  get '/sitemap/pages.xml', to: 'sitemaps#pages', defaults: { format: :xml }

  get '/api/v1/graphql', to: 'graphql#execute'
  post '/api/v1/graphql', to: 'graphql#execute'

  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/v1/graphql' if Rails.env.development?
  # Lookbook auto-mounts at /lookbook in development
end
