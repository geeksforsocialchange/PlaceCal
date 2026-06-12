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

  # Signed, no-login email preferences (not in the sitemap: token-gated)
  get 'email-preferences', to: 'email_preferences#show', as: :email_preferences
  patch 'email-preferences', to: 'email_preferences#update'
  post 'email-preferences/unsubscribe', to: 'email_preferences#one_click_unsubscribe',
                                        as: :email_preferences_unsubscribe

  # ============================================================
  # Legacy & deprecated
  # ============================================================

  # Legacy routes from when some Partners were Places
  get '/places/:id', to: 'partners#show'
  get '/places/:id/events', to: 'partners#show'
  get '/places/:id/events/:year/:month/:day', to: 'partners#show', constraints: ymd
  get '/places/:id/embed', to: 'places#embed'

  # Deprecated: moving to join.placecal.org
  get 'find-placecal', to: 'pages#find_placecal'
  get 'our-story', to: 'pages#our_story'
  get 'community-groups', to: 'pages#community_groups'
  get 'metropolitan-areas', to: 'pages#metropolitan_areas'
  get 'vcses', to: 'pages#vcses'
  get 'housing-providers', to: 'pages#housing_providers'
  get 'social-prescribers', to: 'pages#social_prescribers'
  get 'culture-tourism', to: 'pages#culture_tourism'

  # Deprecated: collections
  resources :collections, only: %i[show]
  get 'winter2017', to: 'collections#show', id: 1
  get 'winter2018', to: 'collections#show', id: 2

  # ============================================================
  # Technical (SEO, API, dev tools)
  # ============================================================
  get '/robots.txt', to: 'pages#robots'
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
