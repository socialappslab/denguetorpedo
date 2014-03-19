Dengue::Application.routes.draw do

  #----------------------------------------------------------------------------
  # Sidekiq monitoring

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  #----------------------------------------------------------------------------

  # TODO: Do we really need these routes? They are used in reports/types.html
  # but their implementation is not intuitive.
  resources :elimination_methods
  resources :elimination_types

  # TODO: What are the torpedos and why are they public???
  # TODO: Why are the phones listed publicly?

  get "torpedos/:id" => "reports#torpedos"
  get '/phones' => "users#phones"

  # TODO: Make this into an actual route.
  # TODO: Are we actually using these routes?
  get '/cupons/sponsor/:id' => "prize_codes#sponsor"

  #----------------------------------------------------------------------------
  # SMS Gateway routes.

  get "/sb/rest/sms/inject" => "sms_gateway#inject"
  get "/sb/rest/sms/notifications" => "sms_gateway#notifications"
  get "/sb/rest/sms/remove" => "sms_gateway#remove"

  #----------------------------------------------------------------------------
  # Users routes.

  # TODO: Are these matches even necessary? Can we remove them or fold them
  # under the :users resource?
  match "/user/:id/prize_codes" => 'prize_codes#index'
  match "/user/:id/prize_codes/:prize_id" => 'prize_codes#show'
  match "/user/:id/prize_codes/:prize_id/redeem/:prize_code_id" => 'prize_codes#redeem'
  match "/user/:id/buy_prize/:prize_id" => 'users#buy_prize'
  resources :users do
    resources :reports, :except => [:show]
    resources :posts
    collection do
      get 'special_new'
      post 'special_create'
      put 'block'
    end
  end

  #----------------------------------------------------------------------------
  # Neighborhoods

  resources :neighborhoods, :only => [:show] do
    resources :reports do
      collection do
        put 'update'
        post 'verify'
        post 'problem'
        post 'gateway'
        get 'notifications'
        get 'types'
      end
      member do
        post 'creditar'
        post 'credit'
        post 'discredit'
      end
    end

    post 'premios/:id' => "prizes#new_prize_code"
    get 'premios/admin' => "prizes#admin"
    resources :prizes, :path => "premios" do
      collection do
        get 'badges'
      end
    end

    resources :houses do
      resources :posts
    end
  end

  #----------------------------------------------------------------------------
  # Deprecated Routes with Neighborhood Redirect Directive
  # The following (3) resources are now nested under the neighborhood resource.
  # We're keeping them around in case users have gotten in the habit of using
  # these routes. Eventually, they should be removed completely. We redirect
  # to the *first* neighborhood as that was the intended behavior before
  # multiple neighborhoods

  # TODO: We're keeping the original routes around so we don't get
  # undefined '_path' errors. At some point, we should refacto these.
  match '/reports'       => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }
  match '/reports/:path' => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :constraints => { :path => ".*" }
  resources :reports do
    collection do
      put 'update'
      post 'verify'
      post 'problem'
      post 'gateway'
      get 'notifications'
      get 'types'
    end
    member do
      post 'creditar'
      post 'credit'
      post 'discredit'
    end
  end

  match '/houses'       => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }
  match '/houses/:path' => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :constraints => { :path => ".*" }
  resources :houses do
    resources :posts
  end


  match '/premios'       => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }
  match '/premios/:path' => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :constraints => { :path => ".*" }
  post 'premios/:id' => "prizes#new_prize_code"
  get '/premios/admin' => "prizes#admin"
  resources :prizes, :path => "premios" do
    collection do
      get 'badges'
    end
  end

  #----------------------------------------------------------------------------
  # User Session

  resource :session, :only => [:new, :create, :destroy]
  match 'exit' => 'sessions#destroy', :as => :logout

  get "password_resets/new"
  resources :password_resets, :only => [:new, :create, :edit, :update]

  #----------------------------------------------------------------------------
  # Prize Codes

  resources :prize_codes, :only => [:new, :create, :destroy, :show, :index], :path => "coupons"

  #----------------------------------------------------------------------------
  # Miscellaneous routes.

  resources :feedbacks
  resources :notices
  resources :sponsors
  get "dashboard/index"
  resources :dashboard
  resources :notifications
  resources :badges
  resources :verifications
  resources :forums, :only => [:index]
  resources :buy_ins, :only => [:new, :create, :destroy]
  resources :group_buy_ins, :only => [:new, :create, :destroy]

  #----------------------------------------------------------------------------
  # Landing Pages routes.

  match "home/:id" => "home#index", :as => "Home"
  root :to        => 'home#index'
  get "faq"       => 'home#faq'
  get "manual"    => "home#manual"
  get "howto"     => "home#howto"
  get "contact"   => 'home#contact'
  get "about"     => 'home#about'
  get "education" => 'home#education'
  get "credit"    => 'home#credit'

  #----------------------------------------------------------------------------

end
