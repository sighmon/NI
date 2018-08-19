FactoryBot.define do

  factory :article do
    sequence(:title) { |n| "article#{n}" }
    publication { DateTime.now }
    issue

  end

end
