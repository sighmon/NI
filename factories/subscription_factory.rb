FactoryGirl.define do
  
  factory :subscription do
    valid_from DateTime.now
    duration 1
    user
  end

end
