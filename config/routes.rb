# frozen_string_literal: true

# config/routes.rb
Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  # Most common route at the top
  devise_for :users, controllers: { omniauth_callbacks: 'admin/omniauth_callbacks', invitations: 'users/invitations' }

  scope module: :admin, as: :admin, constraints: { subdomain: 'admin' } do
    resources :calendars do
      get :select_page, on: :collection
      member do
        post :import
      end
    end
    resources :partners
    resources :places
    resources :turfs
    resources :sites
    resources :supporters
    resources :users do
      member do
        put :assign_turf
      end
    end
    get 'profile' => 'users#profile', :as => 'profile'
    root 'pages#home'
  end

  constraints(::Sites::Local) do
    # get '*' => 'sites#index'
    root 'sites#index'
  end

  ymd = {
    year:       /\d{4}/,
    month:      /\d{1,2}/,
    day:        /\d{1,2}/
  }

  # Events
  resources :events, only: %i[index show]
  get '/events/:year/:month/:day' => 'events#index', constraints: ymd

  # Places
  resources :places, only: %i[index show]
  get '/places/:id/events' => 'places#show'
  get '/places/:id/events/:year/:month/:day' => 'places#show', constraints: ymd
  get '/places/:id/embed' => 'places#embed'

  # Partners
  resources :partners, only: %i[index show]
  get '/partners/:id/events' => 'partners#show'
  get '/partners/:id/events/:year/:month/:day' => 'partners#show', constraints: ymd

  # Calendars
  resources :calendars, only: %i[index show]

  # Collections
  resources :collections, only: %i[show]

  # Static pages
  get 'join', to: 'pages#join'
  get 'bus', to: 'pages#bus'
  get 'privacy', to: 'pages#privacy'

  # Named routes
  get 'winter2017', to: 'collections#show', id: 1

  # Administration
  namespace :superadmin do
    get '/', to: 'users#index', as: :root
    resources :users
    resources :addresses
    resources :calendars do
      post :import
    end
    resources :events
    resources :partners
    resources :places
    resources :collections
    # root 'users#index'
  end

  root 'pages#home'

  # Styleguide
  mount MountainView::Engine => '/styleguide'

  get '/robots.txt' => 'pages#robots'
end
