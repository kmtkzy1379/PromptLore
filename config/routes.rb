Rails.application.routes.draw do
  root "articles#index"
  # resourcesで一括
  resources :articles
end
