Rails.application.routes.draw do
  # Mount Alto engine
  mount Alto::Engine => "/feedback"

  # Defines the root path route ("/")
  # root "posts#index"
end
