FactoryGirl.define do

  factory :user do

    ignore do
      prefix "user"
    end

    sequence(:username) { |n| "#{prefix}#{n}" }
    sequence(:email) { |n| "#{prefix}#{n}@example.com" }
    password "password"
    password_confirmation "password"

    admin false

    factory :institution_user do
      prefix "institution"
      institution true
    end

    factory :admin_user do
      sequence(:username) { |n| "admin#{n}" }
      sequence(:email) { |n| "admin#{n}@example.com" }
      admin true
    end

    factory :child_user do
      sequence(:username) { |n| "child#{n}" }
      association :parent, factory: :institution_user, prefix: "parent"
    end
      
  end

end
