FactoryBot.define do
  
  factory :subscription do
    valid_from { DateTime.now }
    duration 3
    user

    factory :media_subscription do
      duration 120
    end
  end

end
