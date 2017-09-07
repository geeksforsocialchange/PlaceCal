Rails.application.routes.draw do
  resources :partners
  resources :places
  devise_for :users
  resources :calendars
  resources :events
  resources :users

  get 'join', to: 'pages#join'
  root 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  mount MountainView::Engine => "/styleguide"
end
