Dengue::Application.routes.draw do

  #----------------------------------------------------------------------------

  # TODO: Do we really need these routes? They are used in reports/types.html
  # but their implementation is not intuitive.
  resources :elimination_methods
  resources :elimination_types

  #----------------------------------------------------------------------------

  match "/home/:id" => "home#index", :as => "Home"
  match "/faq" => 'home#faq'
  match "/manual" => "home#manual"
  match "/howto" => "home#howto"
  match '/contact' => 'home#contact'
  match 'about' => 'home#about'
  match '/education' => 'home#education'
  match '/credit' => 'home#credit'
  match "/user/:id/prize_codes" => 'prize_codes#index'
  match "/user/:id/prize_codes/:prize_id" => 'prize_codes#show'
  match "/user/:id/prize_codes/:prize_id/redeem/:prize_code_id" => 'prize_codes#redeem'
  match "/user/:id/buy_prize/:prize_id" => 'users#buy_prize'

  #----------------------------------------------------------------------------
  # TODO: What are the torpedos and why are they public???
  # TODO: Why are the phones listed publicly?

  get "torpedos/:id" => "reports#torpedos"
  get '/phones' => "users#phones"

  #----------------------------------------------------------------------------
  # SMS Gateway routes.

  get "/sb/rest/sms/inject" => "sms_gateway#inject"
  get "/sb/rest/sms/notifications" => "sms_gateway#notifications"
  get "/sb/rest/sms/remove" => "sms_gateway#remove"

  #----------------------------------------------------------------------------
  # Coupons

  # TODO: Make this into an actual route.
  get '/cupons/sponsor/:id' => "prize_codes#sponsor"

  #----------------------------------------------------------------------------
  # Users routes.

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
  # Reports routes.

  post "reports/sms"
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

  #----------------------------------------------------------------------------
  # Houses

  resources :houses do
    resources :posts
  end

  #----------------------------------------------------------------------------
  # User Session
  resource :session, :only => [:new, :create, :destroy]
  match 'exit' => 'sessions#destroy', :as => :logout

  #----------------------------------------------------------------------------
  # Password resets

  get "password_resets/new"
  resources :password_resets, :only => [:new, :create, :edit, :update]

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
  resources :neighborhoods, :only => [:show]
  resources :buy_ins, :only => [:new, :create, :destroy]
  resources :group_buy_ins, :only => [:new, :create, :destroy]



  #----------------------------------------------------------------------------
  # Landing Pages routes.

  root :to => 'home#index'

  #----------------------------------------------------------------------------

end
