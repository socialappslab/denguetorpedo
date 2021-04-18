# -*- encoding : utf-8 -*-
Dengue::Application.routes.draw do
  # get "/.well-known/acme-challenge/6iEbJmeMKc1BB34je4Wu1MtrDZemh3cB3YqpHjlp7cc" => 'home#denguechatcom'
  get "/.well-known/acme-challenge/cY1aep05zjfm0KS8w7OR1RJ60PXjbUBtUIOdPJ-5YXk" => "home#denguechatorg"

  #----------------------------------------------------------------------------
  # API routes.



  namespace :api, :defaults => { :format => :json } do
    namespace :v0 do
      resources :users, :only => [:index, :create, :update] do
        get "scores"
        put "membership", :on => :member
      end

      resource :sync, :only => [:show], :controller => :sync do
        put :post
        put :location
        put :visit
        put :inspection
      end

      resources :sessions,    :only => [:create] do
        collection do
          get "current"
          post "registrations"
        end
      end

      #-------------------------------------------------------------------------

      resources :visits,     :only => [:create, :index, :show, :update] do
        get "search", :on => :collection
      end


      #-------------------------------------------------------------------------

      resources :inspections, :only => [:create, :update]
      resources :reports,     :only => [:index, :update, :create, :destroy]

      #-------------------------------------------------------------------------

      resources :csv_reports, :only => [:create, :update, :destroy] do
        collection do
          post "batch"
          post "geolocation"
        end

        member do
          put "verify"
        end
      end

      #-------------------------------------------------------------------------

      resources :posts,       :only => [:index, :create, :show, :destroy] do
        post "like", :on => :member

        resources :comments, :controller => "posts/comments", :only => [:create]
      end

      #-------------------------------------------------------------------------

      resources :locations, :only => [:index, :show, :update, :create] do
        get "house-index", :on => :collection, :action => "house_index"
        get "search", :on => :collection
        get "mobile", :on => :collection
        # get "questions", :on => :collection
        put "questions"
      end

      #-------------------------------------------------------------------------

      resources :comments,       :only => [:destroy] do
        post "like", :on => :member
      end

      #-------------------------------------------------------------------------

      resources :users, :only => [] do
        resources :posts, :controller => "users/posts", :only => [:index]
      end

      #-------------------------------------------------------------------------

      resource :graph, :only => [] do
        get "locations"
        get "green_locations"
        get "timeseries"
      end

      resources :assignments, only: [:index, :create, :update, :destroy]
    end
  end

  #----------------------------------------------------------------------------
  # Dashboard routes.

  namespace :dashboard do
    resources :csv, :controller => "csv_reports", :only => [:index, :new]
    resources :locations, :only => [:index]
    resources :reports,   :only => [:index]
    resources :visits,    :only => [:index]
    resources :sync,    :only => [:index]
    resources :settings, :only => [:index] do
      collection do
        post "create", as: :create
      end
    end

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

  resources :organizations, :only => [:update] do
    get :settings, :on => :collection
    get "users", :on => :collection
    get "teams", :on => :collection
    get "cityblockassigns/:city_block_id", to: "organizations#cityblockassigns", on: :collection
    get "assignments", on: :collection
    get "assignment/:id", to: "organizations#assignment", on: :collection, as: :assignment
    get "assignments/:city_id/barrio/:id_barrio", to: "organizations#ultimos_recorridos_list", on: :collection
    get "assignments/:city_id/barriomenos/:id_barrio", to: "organizations#menos_recorridos_list", on: :collection
    get "assignments/cityselect/:id_city", to: "organizations#city_select", on: :collection
    get "citymap/:id_city", to: "organizations#city_select_map", on: :collection
    post "assignments", to: "organizations#assignments_post", on: :collection, as: :assignments_post
    get "volunteers/:city_id", to: "organizations#volunteers", on: :collection, as: :volunteers_json
    get "territorio", :on => :collection
    get "territorio/:city_id/barrio/:id_barrio", to: "organizations#ultimos_recorridos_list", on: :collection
    get "territorio/:city_id/barriomenos/:id_barrio", to: "organizations#menos_recorridos_list", on: :collection
    get "territorio/cityselect/:id_city", to: "organizations#city_select", on: :collection
    get "cityblockinfo/:city_id", to: "organizations#cityblockinfo", on: :collection
    get "locationinfo/:city_id", to: "organizations#locationinfo", on: :collection
    get "mapcityblock/:neighborhood_id", to: "organizations#mapcityblock", on: :collection
    get "neighborhoodlocation/:neighborhood_id", to: "organizations#neighborhoodlocation", on: :collection
   
    
  end

  #----------------------------------------------------------------------------
  # Landing Pages routes.

  match "home/:id" => "home#index", :as => "Home", :via => :get
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
  match "/user/:id/prize_codes" => 'prize_codes#index', :via => :get
  match "/user/:id/prize_codes/:prize_id" => 'prize_codes#show', :via => :get
  match "/user/:id/prize_codes/:prize_id/redeem/:prize_code_id" => 'prize_codes#redeem', :via => :get

  # TODO: We should limit the routes that we expose for users. :except => here
  # shouldn't really exist.
  resources :users, :except => [:index] do
    resources :reports, :except => [:show]
    resources :conversations, :only => [:index, :show]
    resources :messages,      :only => [:create]

    get "switch", :on => :collection

    collection do
      post "set-cookies", :action => "set_neighborhood_cookie", :as => :set_cookies
    end
  end

  #----------------------------------------------------------------------------
  # Cities

  resources :cities, :only => [:show]

  #----------------------------------------------------------------------------
  # CSV Reports

  resources :csv_reports, :only => [:new, :create, :index, :show] do
    collection do
      get "batch"
    end

    member do
      get "verify"
    end
    get "geolocation", :on => :collection
  end

  get "odk_sync_errors", to: "csv_reports#sync_errors"
  delete "odk_sync_errors", to: "csv_reports#delete_key", as: "delete_odk_key_member"

  #----------------------------------------------------------------------------
  # Neighborhoods
  resources :neighborhoods, :only => [:show] do
    collection do
      get  "invitation"
      post "contact"
    end

    resources :reports, path: "inspections", :except => [:update, :destroy] do
      member do
        get  "coordinator-edit", :action => :coordinator_edit, :as => :coordinator_edit
        patch  "coordinator-update", :action => :coordinator_update, :as => :coordinator_update
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
  match '/reports'       => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :via => :get
  match '/reports/:path' => redirect { |params, request| "/neighborhoods/#{Neighborhood.first.id}" + request.path + (request.query_string.present? ? "?#{request.query_string}" : "") }, :constraints => { :path => ".*" }, :via => :get

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
  match 'exit' => 'sessions#destroy', :as => :logout, :via => :get

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
  # Sidekiq monitoring

  require 'sidekiq/web'
  mount Sidekiq::Web => '/7XpBp7Bgd2cd'


  #----------------------------------------------------------------------------
end
