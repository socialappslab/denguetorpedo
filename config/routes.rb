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
  # TODO: I can't find sms_gateway controller anywhere. Are these supposed to be here?

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

  get "neighborhoods/invitation" => "neighborhoods#invitation", :as => :neighborhood_invitation
  resources :neighborhoods, :only => [:show] do
    resources :reports do
      collection do
        put 'update'
        post 'verify'
        post 'problem'
        get 'types'
      end
      member do
        post 'like'
        post "comment"
        post 'creditar'
        post 'credit'
        post 'discredit'
      end
    end

    resources :houses do
      resources :posts do
        post "like",    :on => :member
        post "comment", :on => :member
      end
    end
  end

  #----------------------------------------------------------------------------
  # Legacy SMS routes.
  # NOTE: Do not change these unless you've also
  # changed the paths in socialappslab/SMSGateway.

  post '/reports/gateway'       => "reports#gateway"
  get  "/reports/notifications" => "reports#notifications"

  #----------------------------------------------------------------------------
  # Deprecated Routes with Neighborhood Redirect Directive
  # The following (2) resources are now nested under the neighborhood resource.
  # We're keeping them around in case users have gotten in the habit of using
  # these routes. Eventually, they should be removed completely. We redirect
  # to the *first* neighborhood as that was the intended behavior before
  # multiple neighborhoods
  # NOTE: Unfortunately, these rules do not account for HTTP verbs besides GET
  # so we won't rely on this being a complete redirect solution.

  # TODO: We're keeping the original routes around so we don't get
  # undefined '_path' errors. At some point, we should refactor these.
  match '/reports'       => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }
  match '/reports/:path' => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :constraints => { :path => ".*" }

  match '/houses'       => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }
  match '/houses/:path' => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :constraints => { :path => ".*" }

  #----------------------------------------------------------------------------
  # Prizes

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
  # Documentation Sections
  resources :documentation_sections, :only => [:edit, :update]

  #----------------------------------------------------------------------------
  # Prize Codes

  resources :prize_codes, :only => [:new, :create, :destroy, :show, :index], :path => "coupons"

  #----------------------------------------------------------------------------
  # Teams

  resources :teams

  #----------------------------------------------------------------------------
  # Miscellaneous routes.

  resources :feedbacks

  resources :notices do
    post "like",    :on => :member
    post "comment", :on => :member
  end

  resources :sponsors
  get "dashboard/index"
  resources :dashboard
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
  post "neighborhood-search" => "home#neighborhood_search", :as => :neighborhood_search

  #----------------------------------------------------------------------------

end
