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

  # Users
  devise_for :users
  resources :users

  # Static pages
  get 'join', to: 'pages#join'

  # Styleguide
  mount MountainView::Engine => "/styleguide"

end
