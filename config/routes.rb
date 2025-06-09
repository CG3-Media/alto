FeedbackBoard::Engine.routes.draw do
  # Root redirects to default board
  root 'boards#redirect_to_default'

  # Board routes
  resources :boards, param: :slug, path: 'boards' do
    resources :tickets do
      resources :comments, only: [:create, :destroy, :show]
      resources :upvotes, only: [:create] do
        collection do
          delete :toggle  # DELETE /boards/:board_slug/tickets/:ticket_id/upvotes/toggle
        end
      end
    end
  end

  # Legacy ticket routes (for backwards compatibility in admin)
  resources :comments, only: [] do
    resources :upvotes, only: [:create, :destroy] do
      collection do
        delete :toggle  # DELETE /comments/:comment_id/upvotes/toggle
      end
    end
  end

  # Admin routes
  namespace :admin do
    root 'dashboard#index'
    resource :settings, only: [:show, :update]
    resources :boards, param: :slug, except: [:show]
    resources :status_sets
  end
end
