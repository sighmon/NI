FactoryBot.define do
  
  factory :subscription do
    valid_from { DateTime.now }
    purchase_date { DateTime.now }
    duration { 6 }
    user

    factory :media_subscription do
      duration { 120 }
    end

    factory :paper_only_subscription do
      duration { 12 }
      paper_only { true }
    end
  end

end
