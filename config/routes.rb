Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  resources :users, only: [ :show, :edit, :update ]

  resources :repositories do
    member do
      get :download
      get :raw_content
      post :toggle_like
      post :restore
      post :toggle_pin
      patch :update_memo
      get :preview_version
    end
  end

  resources :presets do
    member do
      get :download
      get :download_item
      get :raw_content
      post :toggle_like
      post :restore
      post :toggle_pin
      patch :update_memo
      get :preview_version
    end
  end

  resources :tags, only: [ :index ]
  resources :categories, only: [ :index ]
end
