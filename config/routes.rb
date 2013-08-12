NI::Application.routes.draw do

  # Routes for the categories breadcrumbs
  resources :categories, :only => [:index, :show]

  get "guest_passes/index"

  # routes for static pages - help, about etc..
  resources :pages, except: :show

  get "subscriptions/update"

  get "settings/index"

  get "settings/update"

  # Sitemap redirects to S3
  match "/sitemap_index.xml", :controller => "sitemap", :action => "index"
  match "/sitemap.xml", :controller => "sitemap", :action => "sitemap"

  # created by the admin/users controller creation
  # get "users/index"

  # hack to sign in when on a pre-authenticated ip
  get "users/re_sign_in"

  devise_for :users, :controllers => { :registrations => "registrations" } #, :path_names => { :sign_up => "subscribe" }
  # Create a route for users profile page
  # match 'users/:id' => 'users#show', :as => @user
  resources :users, :only => [:show]


  resources :subscriptions do
    new do
      get :express
    end
  end
  # hack to create /subscriptions route
  # resources :subscriptions, :only => [:create]

  resources :issues do
    # Route for importing articles from bricolage to an issue
    resources :articles do
      resources :favourites, :only => [:create, :destroy]
      resources :guest_passes, :only => [:create, :destroy]
      get :body
      get :import
      get :import_images
      get :generate_from_source
      resources :images do
        collection { post :sort }
      end
      # Customise Twitter & Facebook posts using selected text
      get :tweet
      get :wall_post
    end
    resources :purchases, :only => [:new, :create] do
      new do
        get :express
      end
    end
    get :import
    get :import_images
    get :email
    get :email_non_subscribers
  end

  get 'search' => 'articles#search'

  # PayPal payment notification IPN
  # get "payment_notifications/create"
  resource :payment_notifications, :only => [:create]

  namespace :admin do
    root :to => "base#index"
    resources :users do
      get :free_subscription
      get :media_subscription
      get :make_institutional
      get :free_institutional_subscription
      get :become
    end
    resources :subscriptions, :only => [:update]
    resources :settings, :only => [:index, :update], :constraints => { :id => /[a-z_]+/ }
    resources :guest_passes, :only => [:index]
  end

  namespace :institution do
    root :to => "base#index"
    resources :users
  end

  get "home/index"

  # Change the page logged in users are directed to
  # authenticated :user do
  #   root :to => 'issues#index'
  # end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

  # Routes for all Pages - About, help etc..
  get ':id', to: 'pages#show', as: :page
  put ':id', to: 'pages#update', as: :page
  delete ':id', to: 'pages#destroy', as: :page

  # Pretty SEO permalink match for articles
  match '/perma_article/:id' => 'articles#show'

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
