FactoryBot.define do

  factory :user do

    transient do
      prefix "user"
    end

    sequence(:username) { |n| "#{prefix}#{n}" }
    sequence(:email) { |n| "#{prefix}#{n}@example.com" }
    uk_id nil
    uk_expiry nil
    password "password"
    password_confirmation "password"

    # admin false

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

    factory :uk_user do
      # prefix "uk"
      uk_id "123456789"
      uk_expiry (DateTime.now - 1.month)
    end
      
  end

end
