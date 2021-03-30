Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'home#index'
  get '/repository/:id', to: 'home#repository', as: 'repository'
  get '/artifact/:id', to: 'home#artifact', as: 'artifact'
  get '/keyword/:keyword', to: 'home#keyword', as: 'keyword'
end
