Rails.application.routes.draw do

  # Users
  devise_for :users

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
  resources :users

  # Static pages
  get 'join', to: 'pages#join'
  root 'pages#home'

  # Styleguide
  mount MountainView::Engine => "/styleguide"

end
