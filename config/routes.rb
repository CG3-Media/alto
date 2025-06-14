Alto::Engine.routes.draw do
  # Home route - provides default path without named route to avoid conflicts
  get "", to: "boards#redirect_to_default"

  # Global activity across all boards
  get "activity", to: "activity#index"

  # Global search across all boards
  get "search", to: "search#index"

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
    # Admin dashboard with renamed route (avoids any "root" references)
    get "", to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resource :settings, only: [ :show, :update ]
    resources :boards, param: :slug, except: [ :show ] do
      resources :tags, only: [:create, :new, :edit, :update, :destroy]
      get :tags, to: "tags#index"
    end
    resources :status_sets
  end
end
