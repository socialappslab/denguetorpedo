# -*- encoding : utf-8 -*-
Dengue::Application.routes.draw do
  #----------------------------------------------------------------------------
  # API routes.

  namespace :api, :defaults => { :format => :json } do
    namespace :v0 do
      #-------------------------------------------------------------------------

      resources :sessions,    :only => [:create] do
        collection do
          get "current"
        end
      end

      #-------------------------------------------------------------------------

      resources :reports,     :only => [:index, :create, :destroy]

      #-------------------------------------------------------------------------

      resources :csv_reports, :only => [:create, :update] do
        member do
          put "verify"
        end
      end

      #-------------------------------------------------------------------------

      resources :posts,       :only => [:create, :show, :destroy] do
        post "like", :on => :member

        resources :comments, :controller => "posts/comments", :only => [:create]
      end

      #-------------------------------------------------------------------------

      resources :locations, :only => [:index] do
      end

      #-------------------------------------------------------------------------

      resources :comments,       :only => [] do
        post "like", :on => :member
      end

      #-------------------------------------------------------------------------

      resources :users, :only => [] do
        resources :posts, :controller => "users/posts", :only => [:index]
      end

      #-------------------------------------------------------------------------

      resources :neighborhoods, :only => [] do
        resources :posts, :controller => "neighborhoods/posts", :only => [:index]
      end

      #-------------------------------------------------------------------------

      resources :cities, :only => [] do
        resources :posts, :controller => "cities/posts", :only => [:index]
      end

      #-------------------------------------------------------------------------

      resources :teams, :only => [] do
        resources :posts, :controller => "teams/posts", :only => [:index]
      end

      #-------------------------------------------------------------------------

      resource :graph, :only => [] do
        get "locations"
      end
    end
  end

  #----------------------------------------------------------------------------
  # Dashboard routes.

  namespace :dashboard do
    resources :csv, :controller => "csv_reports", :only => [:index, :new]
    resources :locations, :only => [:index]
    resources :reports,   :only => [:index]
    resources :graphs,    :only => [:index] do
      collection do
        get "heatmap"
      end
    end
  end

  #----------------------------------------------------------------------------
  # Coordinator routes

  namespace :coordinator do
    get "/", :to => "home#index"

    resources :users, :only => [:new, :create, :index] do
      member do
        get "block", :action => "block"
      end
    end

    resources :teams, :only => [:index] do
      get "block", :on => :member
    end

    resources :notices, :only => [:new, :create, :show, :edit, :update, :destroy]
  end

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
  get "free-sms"  => "home#free_sms", :as => :free_sms
  post "neighborhood-search" => "home#neighborhood_search", :as => :neighborhood_search

  #----------------------------------------------------------------------------

  # TODO: Do we really need these routes? They are used in reports/types.html
  # but their implementation is not intuitive.
  resources :breeding_sites, :only => [:index]

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

  # TODO: We should limit the routes that we expose for users. :except => here
  # shouldn't really exist.
  resources :users, :except => [:index] do
    resources :reports, :except => [:show]
    resources :conversations, :only => [:index, :show]
    resources :messages,      :only => [:create]

    collection do
      post "set-cookies", :action => "set_neighborhood_cookie", :as => :set_cookies
    end
  end

  #----------------------------------------------------------------------------
  # Cities

  resources :cities, :only => [:show] do
    get "new_show", :on => :member
  end

  #----------------------------------------------------------------------------
  # CSV Reports

  resources :csv_reports, :only => [:new, :create, :index, :show, :destroy] do
    member do
      get "verify"
    end
  end

  #----------------------------------------------------------------------------
  # Neighborhoods

  get "neighborhoods/invitation" => "neighborhoods#invitation", :as => :neighborhood_invitation
  resources :neighborhoods, :only => [:show] do
    resources :reports, :except => [:update, :destroy] do
      member do
        get  "coordinator-edit", :action => :coordinator_edit, :as => :coordinator_edit
        put  "coordinator-update", :action => :coordinator_update, :as => :coordinator_update
        put  "eliminate"
        put  "prepare"
        post "like"
        post "comment"
        put  "verify", :action => "verify_report"
        get  "verify"
      end
    end
  end

  #----------------------------------------------------------------------------
  # Posts

  resources :posts, :only => [:create, :show] do
    post "comment", :on => :member
  end

  #----------------------------------------------------------------------------
  # Comments

  resources :comments, :only => [:destroy]

  #----------------------------------------------------------------------------
  # Legacy SMS routes.
  # NOTE: Do not change these unless you've also
  # changed the paths in socialappslab/SMSGateway Android app.

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

  #----------------------------------------------------------------------------
  # Prizes

  post 'premios/:id' => "prizes#new_prize_code"
  get '/premios/admin' => "prizes#admin"
  resources :prizes, :path => "points" do
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
  resources :documentation_sections, :only => [:new, :edit, :create, :update]

  #----------------------------------------------------------------------------
  # Prize Codes

  resources :prize_codes, :only => [:new, :create, :destroy, :show, :index], :path => "coupons"

  #----------------------------------------------------------------------------
  # Teams

  resources :teams do
    post "join",  :on => :member
    post "leave", :on => :member
  end

  #----------------------------------------------------------------------------
  # Miscellaneous routes.

  resources :feedbacks

  # TODO: We should limit the routes that we expose for notices. :except => here
  # shouldn't really exist.
  resources :notices, :only => [] do
    post "like",    :on => :member
    post "comment", :on => :member
  end

  # TODO: Deprecate sponsors route.
  resources :sponsors
  get "dashboard/index"
  resources :dashboard
  resources :badges
  resources :verifications
  resources :forums, :only => [:index]
  resources :buy_ins, :only => [:new, :create, :destroy]
  resources :group_buy_ins, :only => [:new, :create, :destroy]

  post "time-series-settings", :controller => "home", :action => :time_series_settings, :as => :time_series_settings

  #----------------------------------------------------------------------------
  # Active Admin

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  #----------------------------------------------------------------------------
  # Sidekiq monitoring

  require 'sidekiq/web'
  mount Sidekiq::Web => '/7XpBp7Bgd2cd'

  #----------------------------------------------------------------------------
end
