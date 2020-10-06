Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'

  resources :conversations do
    resources :messages
  end

  resources :users, only: [:index] do
    member do
      post :block
      post :unblock
    end
  end

end
