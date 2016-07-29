FactoryGirl.define do

  factory :purchase do
    association :issue, factory: :published_issue
    user
  end

end

