FactoryGirl.define do

  factory :issue do
    sequence(:title) {|n| "issue#{n}"}
    release DateTime.now

  end

end

