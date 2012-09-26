FactoryGirl.define do

  factory :user do
    username "testuser"
    email "me@example.com"
    password "password"

    admin false

    factory :admin_user do
      username "admin"
      email "admin@example.com"
      admin true
    end
  end

end
