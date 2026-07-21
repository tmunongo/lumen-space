Rails.application.routes.draw do
  root 'projects#index'

  resources :projects do
    member do
      patch :archive
      patch :unarchive
    end
    resources :artifacts do
      member do
        post :fetch_content
        post :add_tag
        delete :remove_tag
      end
      resources :highlights, controller: 'artifact_highlights', only: [:create, :destroy]
    end
    resources :relationships, only: [:index], controller: 'relationships'
  end

  resources :artifact_links, only: [:create, :destroy]

  # Health check
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
