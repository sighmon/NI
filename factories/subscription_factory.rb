FactoryGirl.define do
  
  factory :subscription do
    valid_from { DateTime.now }
    duration 3 
    user
  end

end
