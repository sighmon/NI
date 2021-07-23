FactoryBot.define do

  factory :purchase do
    association :issue, factory: :published_issue
    price_paid { 750 }
    purchase_date { DateTime.now }
    user
  end

end

