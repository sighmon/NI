NI::Application.routes.draw do
  # created by the admin/users controller creation
  # get "users/index"

  devise_for :users, :path_names => { :sign_up => "subscribe" }
  # Create a route for users profile page
  # match 'users/:id' => 'users#show', :as => @user
  resources :users, :only => [:show]

  resource :subscription do
    new do
      get :express
    end
  end
  # hack to create /subscriptions route
  resources :subscriptions, :only => [:create]

  resources :issues do
    resources :articles
    resources :purchases, :only => [:new, :create] do
      new do
        get :express
      end
    end
  end

  namespace :admin do
    root :to => "base#index"
    resources :users
  end

  get "home/index"

  # Change the page logged in users are directed to
  authenticated :user do
    root :to => 'issues#index'
  end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

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
