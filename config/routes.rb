Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'home#index'
  get '/repository/:id', to: 'home#repository', as: 'repository'
  get '/import_run/:id', to: 'home#import_run', as: 'import_run'
  get '/artifact/:id', to: 'home#artifact', as: 'artifact'
  get '/version/:id', to: 'home#version', as: 'paper_trail_version'
  get '/keyword/:keyword', to: 'home#keyword', as: 'keyword'
  get '/keyword_counts', to: 'home#keyword_counts', as: 'keyword_counts'
  get '/reports', to: 'home#reports', as: 'reports'
end
