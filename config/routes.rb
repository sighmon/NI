# NI::Application.routes.draw do

# Rails 5
Rails.application.routes.draw do

  # Routes for the categories breadcrumbs
  resources :categories, :only => [:index, :show, :edit, :update]
  get 'update_categories_colours' => 'categories#colours'

  get "guest_passes/index"

  get "subscriptions/update"

  get "settings/index"

  get "settings/update"

  # Sitemap redirects to S3
  # match "/sitemap_index.xml", :controller => "sitemap", :action => "index"
  get "/sitemap.xml", :controller => "sitemap", :action => "index"

  # created by the admin/users controller creation
  # get "users/index"

  # hack to sign in when on a pre-authenticated ip
  get "users/re_sign_in"

  devise_for :users, :controllers => { :registrations => "registrations", :sessions => "sessions", :passwords => "passwords" } #, :path_names => { :sign_up => "subscribe" }
  # devise_for :users, :controllers => { :sessions => "sessions" } #, :path_names => { :sign_up => "subscribe" }

  devise_scope :user do
    get "/uk_login" => "devise/sessions#new_uk"
  end

  # Create a route for users profile page
  # match 'users/:id' => 'users#show', :as => @user
  post "users/:id(.:format)", :to => 'users#show', :as => :user
  resources :users, :only => [:show]

  resources :subscriptions do
    get :show
    new do
      get :express
    end
  end
  # hack to create /subscriptions route
  # resources :subscriptions, :only => [:create]

  # For iOS to post
  post "issues/:id(.:format)", :to => 'issues#show', :as => :issue

  resources :issues do
    # Route for importing articles from bricolage to an issue
    get :import
    get :import_extra
    get :import_images
    get :email
    get :email_non_subscribers
    get :email_others
    get :email_renew
    get :email_special
    get :zip
    post :send_push_notification
    get :tweet_issue
    get :wall_post_issue
    get :email_issue
    resources :articles do
      resources :favourites, :only => [:create, :destroy]
      resources :guest_passes, :only => [:create, :destroy]
      # get version is used for logged in sessions
      get :body
      # the post version is for the iTunes appStore receipt
      post :body
      # the post version for Android Google Play store receipt
      post :body_android
      get :import
      get :import_images
      get :generate_from_source
      resources :images do
        collection { post :sort }
      end
      post :send_push_notification
      # Customise Twitter & Facebook posts using selected text
      get :tweet
      get :wall_post
      get :email_article
      get :ios_share
      post :ios_share
      get :android_share
      post :android_share
      get :hide_images
    end
    resources :purchases, :only => [:new, :create, :show] do
      new do
        get :express
      end
    end
  end

  get 'search' => 'articles#search'
  get 'popular' => 'articles#popular'
  get 'quick_reads' => 'articles#quick_reads'

  # PayPal payment notification IPN
  # get "payment_notifications/create"
  resource :payment_notifications, :only => [:create]

  # PushRegistrations controller
  resource :push_registrations, only: [:create, :destroy]

  namespace :admin do
    root :to => "base#index"
    get "welcome_email" => "base#welcome_email"
    get "reset_password_instructions_email" => "base#reset_password_instructions_email"
    get "subscription_email" => "base#subscription_email"
    get "magazine_purchase_email" => "base#magazine_purchase_email"
    get "admin_email" => "base#admin_email"
    get "delete_cache" => "base#delete_cache"
    get "users/update_csv" => "users#update_csv"
    get "users/download_csv" => "users#download_csv"
    get "users/search" => "users#search"
    resources :users do
      get :free_subscription
      get :crowdfunding_subscription
      get :media_subscription
      get :make_institutional
      get :free_silent_subscription
      post :free_silent_subscription
      get :become
    end
    resources :subscriptions, :only => [:update]
    resources :settings, :only => [:index, :update], :constraints => { :id => /[a-z_]+/ }
    resources :guest_passes, :only => [:index]
    resources :push_registrations, :only => [:index]
    namespace :push_registrations do
      get :import
    end
    resources :push_notifications, :only => [:index, :destroy]
    namespace :push_notifications do
      post :send_notifications
    end
  end

  namespace :institution do
    root :to => "base#index"
    resources :users
  end

  get "home/index"
  get "newsstand" => "home#newsstand"
  get "free" => "home#free"
  get "inapp" => "home#inapp"
  get "google_merchant_feed" => "home#google_merchant_feed"
  get "apple_news" => "home#apple_news"
  get "apple-app-site-association" => "home#apple_app_site_association"
  get "rss" => "home#apple_news"
  get "latest_cover" => "home#latest_cover"
  get "tweet_url" => "home#tweet_url"
  get "wall_post_url" => "home#wall_post_url"
  get "email_url" => "home#email_url"

  # Change the page logged in users are directed to
  # authenticated :user do
  #   root :to => 'issues#index'
  # end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

  # Pretty SEO permalink match for articles
  get '/perma_article/:id' => 'articles#show'

  # Routes for all Pages - About, help etc..
  get 'pages', to: 'pages#index'
  get ':id', to: 'pages#show', as: :page
  patch ':id', to: 'pages#update'#, as: :page
  delete ':id', to: 'pages#destroy'#, as: :page

  # routes for static pages - help, about etc..
  resources :pages, except: :show

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
