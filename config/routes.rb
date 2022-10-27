# frozen_string_literal: true

# config/routes.rb
Rails.application.routes.draw do
  # User login stuff
  devise_for :users,
             controllers: {
               invitations: 'users/invitations',
               sessions: 'users/sessions',
               passwords: 'users/passwords'
             }

  # Static pages
  get 'join', to: 'joins#new'
  post 'join', to: 'joins#create'
  get 'privacy', to: 'pages#privacy'
  get 'find-placecal', to: 'pages#find_placecal'
  get 'our-story', to: 'pages#our_story'

  get 'community-groups', to: 'pages#community_groups'
  get 'metropolitan-areas', to: 'pages#metropolitan_areas'
  get 'vcses', to: 'pages#vcses'
  get 'housing-providers', to: 'pages#housing_providers'
  get 'social-prescribers', to: 'pages#social_prescribers'
  get 'culture-tourism', to: 'pages#culture_tourism'

  scope module: :admin, as: :admin, constraints: { subdomain: 'admin' } do
    resources :articles
    resources :calendars do
      member do
        post :import
      end
    end
    resources :collections
    resources :neighbourhoods
    resources :partners do
      collection do
        match :setup, via: %i[get post]
      end
    end
    resources :tags
    resources :sites
    resources :supporters
    resources :users do
      member do
        patch :update_profile
      end
    end
    get 'profile' => 'users#profile', as: :profile
    get 'jobs' => 'jobs#index', as: :jobs

    root 'pages#home'
  end

  constraints(::Sites::Local) do
    get '/' => 'sites#index'
  end

  root 'pages#home'

  ymd = { year: /\d{4}/,
          month: /\d{1,2}/,
          day: /\d{1,2}/ }

  # Events
  resources :events, only: %i[index show]
  get '/events/:year/:month/:day' => 'events#index', constraints: ymd

  # Partners
  resources :partners, only: %i[index show]
  get '/partners/:id/events' => 'partners#show'
  get '/partners/:id/events/:year/:month/:day' => 'partners#show', constraints: ymd
  get '/places' => 'partners#index' # Removing separate Places view for now.
  get '/partners/:id/embed' => 'places#embed'

  # news
  resources :news, only: %i[index show]

  # Legacy routes from when some Partners were Places. Don't let Google down...
  get '/places/:id' => 'partners#show'
  get '/places/:id/events' => 'partners#show'
  get '/places/:id/events/:year/:month/:day' => 'partners#show', constraints: ymd
  get '/places/:id/embed' => 'places#embed'

  # Calendars
  resources :calendars, only: %i[index show]

  # Collections
  resources :collections, only: %i[show]

  # Named routes
  get 'winter2017', to: 'collections#show', id: 1
  get 'winter2018', to: 'collections#show', id: 2

  # Styleguide
  mount MountainView::Engine => '/styleguide'

  get '/robots.txt' => 'pages#robots'

  post '/api/v1/graphql', to: 'graphql#execute'

  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/api/v1/graphql' if Rails.env.development?
end
