Alto::Engine.routes.draw do
  # Root redirects to default board
  root "boards#redirect_to_default"

  # Global activity across all boards
  get "activity", to: "activity#index"

  # Board routes
  resources :boards, param: :slug, path: "boards" do
    get "activity", to: "activity#index"
    get "archive", to: "archive#show"
    resources :tickets do
      member do
        patch :archive, to: "archive#archive"
        patch :unarchive, to: "archive#unarchive"
      end
      resources :comments, only: [ :create, :destroy, :show ]
      resources :subscribers, only: [ :index, :create, :destroy ] do
        collection do
          delete :unsubscribe_me  # DELETE /boards/:board_slug/tickets/:ticket_id/subscribers/unsubscribe_me
        end
      end
      resources :upvotes, only: [ :create ] do
        collection do
          delete :toggle  # DELETE /boards/:board_slug/tickets/:ticket_id/upvotes/toggle
        end
      end
    end
  end

  # Legacy ticket routes (for backwards compatibility in admin)
  resources :comments, only: [] do
    resources :upvotes, only: [ :create, :destroy ] do
      collection do
        delete :toggle  # DELETE /comments/:comment_id/upvotes/toggle
      end
    end
  end

  # Admin routes
  namespace :admin do
    root "dashboard#index"
    resource :settings, only: [ :show, :update ]
    resources :boards, param: :slug, except: [ :show ]
    resources :status_sets
  end
end
