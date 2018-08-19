FactoryBot.define do

  factory :page do
    sequence(:title) { |n| "title#{n}" }
    sequence(:permalink) { |n| "permalink#{n}" }
    body { "body text" }
  end

end
