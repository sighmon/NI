FactoryGirl.define do

  factory :user do
    sequence(:username) { |n| "testuser#{n}" }
    sequence(:email) { |n| "me#{n}@example.com" }
    password "password"

    admin false

    factory :admin_user do
      sequence(:username) { |n| "admin#{n}" }
      sequence(:email) { |n| "admin#{n}@example.com" }
      admin true
    end
  end

end
