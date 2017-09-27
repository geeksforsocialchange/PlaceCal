# config/routes.rb
Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  # Most common route at the top
  root 'pages#home'

  # Core resources
  resources :events, only: %i[index show]
  get '/events/:year/:month/:day' => 'events#index', constraints: {
    year:       /\d{4}/,
    month:      /\d{1,2}/,
    day:        /\d{1,2}/
  }
  resources :places, only: %i[index show]
  get '/places/:id/events' => 'places#show'
  get '/places/:id/events/:year/:month/:day' => 'places#show', constraints: {
    year:       /\d{4}/,
    month:      /\d{1,2}/,
    day:        /\d{1,2}/
  }
  resources :partners, only: %i[index show]
  resources :calendars, only: %i[index show]

  # Users
  devise_for :users
  resources :users

  # Static pages
  get 'join', to: 'pages#join'

  # Administration
  namespace :admin do
    resources :users
    resources :addresses
    resources :calendars
    resources :events
    resources :partners
    resources :places

    root to: 'users#index'
  end

  # Styleguide
  mount MountainView::Engine => '/styleguide'
end
