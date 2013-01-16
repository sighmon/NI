FactoryGirl.define do

  factory :article do
    title "title"
    publication DateTime.now
    issue
  end

end
