Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "orders#new"
  resources :orders, only: [:new, :show, :create, :index, :destroy] do
    member do
      post 'complete'
    end
  end

  get '/guess' => 'guess#show'
  post '/guess' => 'guess#create'
end
