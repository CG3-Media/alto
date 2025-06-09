FeedbackBoard::Engine.routes.draw do
  # Root redirects to default board
  root 'boards#redirect_to_default'

  # Board routes
  resources :boards, param: :slug, path: 'boards' do
    resources :tickets do
      resources :comments, only: [:create, :destroy]
      resources :upvotes, only: [:create, :destroy]
    end
  end

  # Legacy ticket routes (for backwards compatibility in admin)
  resources :comments, only: [] do
    resources :upvotes, only: [:create, :destroy]
  end

  # Admin routes
  namespace :admin do
    root 'dashboard#index'
    resource :settings, only: [:show, :update]
    resources :boards, except: [:show]
  end
end
