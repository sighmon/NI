FactoryGirl.define do

  factory :issue do
    sequence(:title) {|n| "issue#{n}"}
    release DateTime.now

    factory :published_issue do
    	published true
    end

  end

end

