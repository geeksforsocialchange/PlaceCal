Rails.application.routes.draw do

  # Most common route at the top
  root 'pages#home'

  # Core resources
  resources :partners
  resources :places
  resources :calendars
  resources :events
  get '/events/:year/:month/:day' => 'events#index', constraints: {
    year:       /\d{4}/,
    month:      /\d{1,2}/,
    day:        /\d{1,2}/
  }
  get '/activities' => 'events#activities'
  get '/activities/:year/:month/:day' => 'events#activities', constraints: {
    year:       /\d{4}/,
    month:      /\d{1,2}/,
    day:        /\d{1,2}/
  }

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

    root to: "users#index"
  end

  # Styleguide
  mount MountainView::Engine => "/styleguide"

end
