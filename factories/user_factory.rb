FactoryGirl.define do

  factory :user do
    username "testuser"
    email "me@example.com"
    password "password"
  end

  factory :admin_user, :class => User do
    username "admin"
    email "admin@example.com"
    password "password"
    admin true 
  end
end
