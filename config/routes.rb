Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  resources :users, only: [ :show, :edit, :update ]

  resources :repositories do
    member do
      get :download
      post :toggle_like
    end
  end

  resources :presets do
    member do
      get :download
      get :download_item
      post :toggle_like
    end
  end

  resources :tags, only: [ :index ]
  resources :categories, only: [ :index ]
end
