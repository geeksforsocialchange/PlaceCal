# config/routes.rb
Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  # Most common route at the top
  root 'pages#home'

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

  # Users
  devise_for :users
  resources :users

  # Static pages
  get 'join', to: 'pages#join'

  # Named routes
  get 'winter2017', to: 'collections#show', id: 1

  # Administration
  namespace :admin do
    resources :users
    resources :addresses
    resources :calendars do
      post :import
    end
    resources :events
    resources :partners
    resources :places
    resources :collections

    root to: 'users#index'
  end

  namespace :manager do
    resources :calendars
  end

  # Styleguide
  mount MountainView::Engine => '/styleguide'
end
