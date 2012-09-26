FactoryGirl.define do
  
  factory :subscription do
    expiry_date DateTime.tomorrow
    user
  end

end
