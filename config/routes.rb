Rails.application.routes.draw do

    # V1 of API
    namespace :api do
        namespace :v1 do

            resources :account do
                collection do
                    post :upload
                    post 'new' => 'account#create'
                    get ':p1', to: 'account#index', constraints: { p1: /[^\/]+/ }
                end
            end

            resources :lead do
                collection { post :import}
                collection do
                    post :new
                    put :edit
                end
            end

        end
    end

    # Set Root Url
    authenticated :user do
        root 'query#index'
        #root 'users#show'
    end 
    root to: 'homepage#index'




    # ALL ROUTES FOR USERS NOT SIGNED IN
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)
    resources :demos, only: [:new, :create]
    devise_for :users





    
    resources :users
    resources :query

    # Nested In Client Companies
    resource :client_companies, path: '', only: [:edit, :update, :delete] do 


    end

    resources :leads do
        collection { post :import_to_campaign}
        collection { get :fields}
    end
    resources :contacts
    resources :accounts


end