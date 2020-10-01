Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'

  resources :conversations do
    resources :messages
  end

end
