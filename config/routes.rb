Rails.application.routes.draw do
  get 'home', to: 'home#index'

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_scope :user do
    root to: 'users/sessions#new'
    get 'sign_in', to: 'users/sessions#new'
    get '/users/sign_out', to: 'users/sessions#destroy'
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # Handle error routes
  match "/404", :to => "errors#error_404", :via => :all
  match "/500", :to => "errors#error_500", :via => :all

  # Handle all application routes
  resources :search_logs, only: [:index]
  resources :search_stats, only: [:index]
  resources :import_reports, only: [:index]
  resources :ip_lookups, only: [:index]
  get '/repository/:id', to: 'home#repository', as: 'repository'
  get '/import_run/:id', to: 'home#import_run', as: 'import_run'
  post '/import_run/:id/accept', to: 'home#accept_run', as: 'accept_run'
  post '/import_run/:id/reject', to: 'home#reject_run', as: 'reject_run'
  get '/artifact/:id', to: 'home#artifact', as: 'artifact'
  get '/version/:id', to: 'home#version', as: 'paper_trail_version'
  get '/keyword/:keyword', to: 'home#keyword', as: 'keyword'
  get '/keyword_counts', to: 'home#keyword_counts', as: 'keyword_counts'
  get '/repository_report', to: 'home#repository_report', as: 'repository_report'
  get '/repository_missing/:id', to: 'home#repository_missing', as: 'repository_missing'
end
