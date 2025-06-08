FeedbackBoard::Engine.routes.draw do
  root 'tickets#index'

  resources :tickets do
    resources :comments, only: [:create, :destroy]
    resources :upvotes, only: [:create, :destroy]
  end

  resources :comments, only: [] do
    resources :upvotes, only: [:create, :destroy]
  end
end
